import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'local_storage_service.dart';

/// Read-only tracking of EVM wallets (Base chain). No keys, no signing —
/// balance queries via the public Base RPC + token balanceOf calls,
/// USD pricing via CoinGecko's free API.
///
/// Special-cases the Liquid Loans protocol: LOAN staked in the staking
/// contract doesn't show in the wallet's token balance, so we read
/// `stakes(address)` / `getPendingUSDLGain(address)` / `getPendingETHGain(address)`
/// directly from the staking contract (verified on-chain 2026-08-05).
class EvmWalletService {
  static const String _baseRpc = 'https://mainnet.base.org';
  static const int _chainId = 8453;

  // Liquid Loans protocol on Base (verified on-chain 2026-08-05)
  static const String loanToken = '0x68b8102d404c46b5b4adfcaeeeee415ecfe4203f';
  static const String usdlToken = '0x78e8cf657742e10eac8f64007615aa741fc76414';
  static const String loanStakingContract = '0x9e991A40E7d08B8A85AD51A0D00B921B92Dc649E';
  // Function selectors (keccak, verified against live contract)
  static const String _selStakes = '0x16934fc4'; // stakes(address)
  static const String _selPendingUsdl = '0x816ddaa1'; // getPendingUSDLGain(address)
  static const String _selPendingEth = '0x8b9345ad'; // getPendingETHGain(address)
  // LOAN has no public market/DEX pair on Base — price is protocol-internal.
  // Default from app screenshot 2026-08-05; user-updatable via setLoanPrice().
  static const double defaultLoanPriceUsd = 0.00000119;

  /// Major Base tokens we check balances for. address -> (symbol, decimals, coingeckoId)
  static const Map<String, ({String symbol, int decimals, String cgId})> _tokens = {
    '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913': (symbol: 'USDC', decimals: 6, cgId: 'usd-coin'),
    '0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA': (symbol: 'USDbC', decimals: 6, cgId: 'usd-coin'),
    '0x4200000000000000000000000000000000000006': (symbol: 'WETH', decimals: 18, cgId: 'ethereum'),
    '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf': (symbol: 'cbBTC', decimals: 8, cgId: 'bitcoin'),
    '0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb': (symbol: 'DAI', decimals: 18, cgId: 'dai'),
    '0x940181a94A35A4569E4529A3CDfB74e38FD98631': (symbol: 'AERO', decimals: 18, cgId: 'aerodrome-finance'),
  };

  int _rpcId = 0;

  Future<BigInt> _ethCall(String to, String data) async {
    final resp = await http
        .post(
          Uri.parse(_baseRpc),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': ++_rpcId,
            'method': 'eth_call',
            'params': [
              {'to': to, 'data': data},
              'latest',
            ],
          }),
        )
        .timeout(const Duration(seconds: 12));
    final body = jsonDecode(resp.body);
    final result = body['result'] as String?;
    if (result == null || result == '0x') return BigInt.zero;
    return BigInt.parse(result.substring(2), radix: 16);
  }

  Future<double> _ethBalance(String address) async {
    final resp = await http
        .post(
          Uri.parse(_baseRpc),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': ++_rpcId,
            'method': 'eth_getBalance',
            'params': [address, 'latest'],
          }),
        )
        .timeout(const Duration(seconds: 12));
    final body = jsonDecode(resp.body);
    final hex = body['result'] as String? ?? '0x0';
    final wei = BigInt.parse(hex.substring(2), radix: 16);
    return wei / BigInt.from(10).pow(18);
  }

  /// balanceOf(address) = 0x70a08231 + 32-byte padded address
  Future<double> _tokenBalance(String token, String owner, int decimals) async {
    final padded = owner.substring(2).toLowerCase().padLeft(64, '0');
    final raw = await _ethCall(token, '0x70a08231$padded');
    return raw / BigInt.from(10).pow(decimals);
  }

  Future<Map<String, double>> _prices() async {
    try {
      final ids = {'ethereum', ..._tokens.values.map((t) => t.cgId)}.join(',');
      final resp = await http
          .get(Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=$ids&vs_currencies=usd'))
          .timeout(const Duration(seconds: 12));
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return body.map((k, v) => MapEntry(k, ((v as Map)['usd'] as num).toDouble()));
    } catch (e) {
      debugPrint('CoinGecko price fetch failed: $e');
      return {};
    }
  }

  /// Fetch a wallet's full position on Base. Returns a map with total_usd,
  /// per-asset breakdown, and metadata. Never throws — returns is_live=false
  /// with whatever partial data we got on failure.
  Future<Map<String, dynamic>> fetchWallet(String address, {String label = 'Base Wallet'}) async {
    final prices = await _prices();
    final assets = <Map<String, dynamic>>[];
    double totalUsd = 0.0;
    bool anySuccess = false;

    try {
      final eth = await _ethBalance(address);
      anySuccess = true;
      if (eth > 0) {
        final usd = eth * (prices['ethereum'] ?? 0.0);
        totalUsd += usd;
        assets.add({'symbol': 'ETH', 'amount': eth, 'usd': usd});
      }
    } catch (e) {
      debugPrint('ETH balance fetch failed for $address: $e');
    }

    for (final entry in _tokens.entries) {
      try {
        final t = entry.value;
        final bal = await _tokenBalance(entry.key, address, t.decimals);
        anySuccess = true;
        if (bal > 0) {
          final usd = bal * (prices[t.cgId] ?? 0.0);
          totalUsd += usd;
          assets.add({'symbol': t.symbol, 'amount': bal, 'usd': usd});
        }
      } catch (e) {
        debugPrint('Token balance fetch failed ${entry.value.symbol}: $e');
      }
    }

    return {
      'address': address,
      'label': label,
      'chain_id': _chainId,
      'total_usd': totalUsd,
      'assets': assets,
      'is_live': anySuccess,
      'source': anySuccess ? 'base_rpc' : 'unavailable',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  /// Liquid Loans staking position for [address], read live from the staking
  /// contract. Returns null if the address has no LOAN stake. LOAN priced with
  /// the stored/manual price (no public market on Base).
  Future<Map<String, dynamic>?> fetchLiquidLoansPosition(String address) async {
    final padded = address.substring(2).toLowerCase().padLeft(64, '0');

    double stakedLoan = 0.0, pendingUsdl = 0.0, pendingEth = 0.0;
    try {
      final raw = await _ethCall(loanStakingContract, '$_selStakes$padded');
      stakedLoan = raw / BigInt.from(10).pow(18);
    } catch (e) {
      debugPrint('LL stakes fetch failed: $e');
      return null; // can't confirm position exists
    }
    if (stakedLoan <= 0) return null;

    try {
      final raw = await _ethCall(loanStakingContract, '$_selPendingUsdl$padded');
      pendingUsdl = raw / BigInt.from(10).pow(18);
    } catch (e) {
      debugPrint('LL pending USDL fetch failed: $e');
    }
    try {
      final raw = await _ethCall(loanStakingContract, '$_selPendingEth$padded');
      pendingEth = raw / BigInt.from(10).pow(18);
    } catch (e) {
      debugPrint('LL pending ETH fetch failed: $e');
    }

    final prices = await _prices();
    final loanPrice = await LocalStorageService.loadLoanPrice() ?? defaultLoanPriceUsd;
    final stakedUsd = stakedLoan * loanPrice;
    final pendingUsdlUsd = pendingUsdl * (prices['usd-coin'] ?? 1.0); // USDL ~$1
    final pendingEthUsd = pendingEth * (prices['ethereum'] ?? 0.0);

    return {
      'protocol': 'Liquid Loans',
      'staked_loan': stakedLoan,
      'loan_price_usd': loanPrice,
      'loan_price_source': 'manual',
      'staked_usd': stakedUsd,
      'pending_usdl': pendingUsdl,
      'pending_usdl_usd': pendingUsdlUsd,
      'pending_eth': pendingEth,
      'pending_eth_usd': pendingEthUsd,
      'total_usd': stakedUsd + pendingUsdlUsd + pendingEthUsd,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // ---- tracked wallet persistence ----

  Future<List<Map<String, dynamic>>> loadTrackedWallets() =>
      LocalStorageService.loadEvmWallets();

  Future<void> trackWallet(String address, String label) async {
    final wallets = await loadTrackedWallets();
    if (!wallets.any((w) => (w['address'] as String?)?.toLowerCase() == address.toLowerCase())) {
      wallets.add({'address': address, 'label': label, 'chain_id': _chainId});
      await LocalStorageService.saveEvmWallets(wallets);
    }
  }
}
