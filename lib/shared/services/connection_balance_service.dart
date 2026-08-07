import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'connection_service.dart';
import 'evm_wallet_service.dart';

/// Fetches live balances for user connections.
///
/// Tier 1 (addresses): BTC via Blockstream's free API, EVM via the existing
/// Base RPC service, SOL via the public Solana JSON-RPC. Prices from
/// CoinGecko's free API.
///
/// Tier 2 (exchange API keys): Coinbase Advanced Trade (public /products +
/// accounts via legacy v2 endpoint signing is intentionally not shipped from
/// the client — see note in [fetchExchangeBalance]).
class ConnectionBalanceService {
  /// Fetch balance for a tier-1 address connection. Never throws.
  static Future<Map<String, dynamic>> fetchAddressBalance(UserConnection c) async {
    switch (c.chain) {
      case 'btc':
        return _fetchBtc(c.address!);
      case 'sol':
        return _fetchSol(c.address!);
      case 'evm':
      default:
        final data = await EvmWalletService().fetchWallet(c.address!, label: c.label);
        return data;
    }
  }

  // ---- BTC ----
  static Future<Map<String, dynamic>> _fetchBtc(String address) async {
    double btc = 0.0;
    bool live = false;
    try {
      final resp = await http
          .get(Uri.parse('https://blockstream.info/api/address/$address'))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        final funded = (j['chain_stats']['funded_txo_sum'] as num) +
            (j['mempool_stats']['funded_txo_sum'] as num);
        final spent = (j['chain_stats']['spent_txo_sum'] as num) +
            (j['mempool_stats']['spent_txo_sum'] as num);
        btc = (funded - spent) / 1e8;
        live = true;
      }
    } catch (e) {
      debugPrint('BTC fetch failed: $e');
    }
    final price = await _cgPrice('bitcoin');
    final usd = price != null ? btc * price : 0.0;
    return {
      'address': address,
      'label': 'Bitcoin',
      'total_usd': usd,
      'assets': [if (btc > 0) {'symbol': 'BTC', 'amount': btc, 'usd': usd}],
      'is_live': live,
      'source': live ? 'blockstream' : 'unavailable',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // ---- SOL ----
  static Future<Map<String, dynamic>> _fetchSol(String address) async {
    double sol = 0.0;
    bool live = false;
    try {
      final resp = await http
          .post(
            Uri.parse('https://api.mainnet-beta.solana.com'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'id': 1,
              'method': 'getBalance',
              'params': [address],
            }),
          )
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        final lamports = (j['result']?['value'] as num?) ?? 0;
        sol = lamports / 1e9;
        live = true;
      }
    } catch (e) {
      debugPrint('SOL fetch failed: $e');
    }
    final price = await _cgPrice('solana');
    final usd = price != null ? sol * price : 0.0;
    return {
      'address': address,
      'label': 'Solana',
      'total_usd': usd,
      'assets': [if (sol > 0) {'symbol': 'SOL', 'amount': sol, 'usd': usd}],
      'is_live': live,
      'source': live ? 'solana_rpc' : 'unavailable',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // ---- CoinGecko helper ----
  static Future<double?> _cgPrice(String id) async {
    try {
      final r = await http
          .get(Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=$id&vs_currencies=usd'))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body);
        return (j[id]?['usd'] as num?)?.toDouble();
      }
    } catch (_) {}
    return null;
  }

  // ---- Tier 2: exchanges ----

  /// Exchange balance fetch. Each exchange has its own auth scheme; the
  /// signed ones (Kraken, Gemini, Binance) use HMAC-SHA256/512 over the
  /// request — computed locally, keys never leave the device.
  /// Never throws; returns is_live=false on failure.
  static Future<Map<String, dynamic>> fetchExchangeBalance(UserConnection c) async {
    switch (c.platformId) {
      case 'kraken':
        return _fetchKraken(c);
      case 'binance':
      case 'binance_us':
        return _fetchBinance(c);
      case 'gemini':
        return _fetchGemini(c);
      default:
        // Coinbase/Crypto.com/OKX/Bybit/KuCoin/Bitstamp: auth flows vary
        // (OAuth, JWT, passphrase headers). Connection is stored; balance
        // fetch lands when the per-exchange signer is added.
        return _unsupported(c);
    }
  }

  static Map<String, dynamic> _unsupported(UserConnection c) => {
        'address': null,
        'label': c.label,
        'total_usd': 0.0,
        'assets': const [],
        'is_live': false,
        'source': 'signer_pending',
        'last_updated': DateTime.now().toIso8601String(),
      };

  static Future<Map<String, dynamic>> _fetchKraken(UserConnection c) async {
    try {
      final nonce = DateTime.now().millisecondsSinceEpoch.toString();
      const path = '/0/private/Balance';
      final body = 'nonce=$nonce';
      // Kraken signature: HMAC-SHA512(path + sha256(nonce+body), base64(secret))
      final sha = sha256.convert(utf8.encode(nonce + body));
      final hmacSha = Hmac(sha512, base64Decode(c.apiSecret!));
      final sig = hmacSha.convert(utf8.encode(path) + sha.bytes);
      final resp = await http
          .post(
            Uri.parse('https://api.kraken.com$path'),
            headers: {
              'API-Key': c.apiKey!,
              'API-Sign': base64Encode(sig.bytes),
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        final result = j['result'] as Map<String, dynamic>? ?? {};
        // Kraken returns asset->balance strings (XXBT, ZUSD, XETH, ...)
        final assets = <Map<String, dynamic>>[];
        double totalUsd = 0.0;
        for (final e in result.entries) {
          final amount = double.tryParse('${e.value}') ?? 0.0;
          if (amount <= 0) continue;
          final symbol = _krakenSymbol(e.key);
          final usd = await _usdValue(symbol, amount);
          totalUsd += usd;
          assets.add({'symbol': symbol, 'amount': amount, 'usd': usd});
        }
        return {
          'address': null,
          'label': c.label,
          'total_usd': totalUsd,
          'assets': assets,
          'is_live': true,
          'source': 'kraken_api',
          'last_updated': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('Kraken fetch failed: $e');
    }
    return _unsupported(c)..['source'] = 'unavailable';
  }

  static String _krakenSymbol(String code) {
    const map = {
      'XXBT': 'BTC', 'XBT': 'BTC', 'XETH': 'ETH', 'ZUSD': 'USD', 'USD': 'USD',
      'ZEUR': 'EUR', 'XRP': 'XRP', 'SOL': 'SOL', 'USDC': 'USDC', 'USDT': 'USDT',
      'DOT': 'DOT', 'ADA': 'ADA', 'LINK': 'LINK', 'TAO': 'TAO',
    };
    return map[code] ?? code.replaceAll(RegExp(r'^[XZ]'), '');
  }

  static Future<Map<String, dynamic>> _fetchBinance(UserConnection c) async {
    try {
      final host = c.platformId == 'binance_us' ? 'api.binance.us' : 'api.binance.com';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final query = 'timestamp=$ts';
      final sig = Hmac(sha256, utf8.encode(c.apiSecret!)).convert(utf8.encode(query)).toString();
      final resp = await http
          .get(
            Uri.parse('https://$host/api/v3/account?$query&signature=$sig'),
            headers: {'X-MBX-APIKEY': c.apiKey!},
          )
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final j = jsonDecode(resp.body);
        final balances = j['balances'] as List? ?? [];
        final assets = <Map<String, dynamic>>[];
        double totalUsd = 0.0;
        for (final b in balances) {
          final amount = (double.tryParse('${b['free']}') ?? 0.0) +
              (double.tryParse('${b['locked']}') ?? 0.0);
          if (amount <= 0) continue;
          final symbol = b['asset'] as String;
          final usd = await _usdValue(symbol, amount);
          totalUsd += usd;
          assets.add({'symbol': symbol, 'amount': amount, 'usd': usd});
        }
        return {
          'address': null,
          'label': c.label,
          'total_usd': totalUsd,
          'assets': assets,
          'is_live': true,
          'source': 'binance_api',
          'last_updated': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('Binance fetch failed: $e');
    }
    return _unsupported(c)..['source'] = 'unavailable';
  }

  static Future<Map<String, dynamic>> _fetchGemini(UserConnection c) async {
    try {
      final payload = {
        'request': '/v1/balances',
        'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      final b64 = base64Encode(utf8.encode(jsonEncode(payload)));
      final sig = Hmac(sha384, utf8.encode(c.apiSecret!)).convert(utf8.encode(b64)).toString();
      final resp = await http
          .post(
            Uri.parse('https://api.gemini.com/v1/balances'),
            headers: {
              'X-GEMINI-APIKEY': c.apiKey!,
              'X-GEMINI-PAYLOAD': b64,
              'X-GEMINI-SIGNATURE': sig,
            },
          )
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List;
        final assets = <Map<String, dynamic>>[];
        double totalUsd = 0.0;
        for (final b in list) {
          final amount = double.tryParse('${b['amount']}') ?? 0.0;
          if (amount <= 0) continue;
          final symbol = (b['currency'] as String).toUpperCase();
          final usd = await _usdValue(symbol, amount);
          totalUsd += usd;
          assets.add({'symbol': symbol, 'amount': amount, 'usd': usd});
        }
        return {
          'address': null,
          'label': c.label,
          'total_usd': totalUsd,
          'assets': assets,
          'is_live': true,
          'source': 'gemini_api',
          'last_updated': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      debugPrint('Gemini fetch failed: $e');
    }
    return _unsupported(c)..['source'] = 'unavailable';
  }

  /// Symbol → USD via CoinGecko's simple price map (best effort).
  static Future<double> _usdValue(String symbol, double amount) async {
    const ids = {
      'BTC': 'bitcoin', 'ETH': 'ethereum', 'SOL': 'solana', 'XRP': 'ripple',
      'ADA': 'cardano', 'DOT': 'polkadot', 'LINK': 'chainlink', 'TAO': 'bittensor',
      'DOGE': 'dogecoin', 'LTC': 'litecoin', 'AVAX': 'avalanche-2', 'MATIC': 'matic-network',
    };
    if (symbol == 'USD' || symbol == 'USDC' || symbol == 'USDT') return amount;
    final id = ids[symbol];
    if (id == null) return 0.0;
    final price = await _cgPrice(id);
    return price != null ? amount * price : 0.0;
  }
}
