import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// How a platform connects to Float.
enum ConnectionTier {
  /// Paste a public address — read-only, no keys (hardware wallets, self-custody).
  address,
  /// Read-only API key + secret generated on the exchange.
  apiKey,
  /// Traditional brokerage — only reachable via an aggregator (Plaid/SnapTrade).
  brokerage,
}

/// A platform the app knows how to connect to.
class PlatformConnector {
  final String id;
  final String name;
  final String icon;
  final ConnectionTier tier;
  final String blurb;
  final List<String> addressHints; // tier 1: which chains to ask for

  const PlatformConnector({
    required this.id,
    required this.name,
    required this.icon,
    required this.tier,
    required this.blurb,
    this.addressHints = const [],
  });
}

/// A connection the user has actually added.
class UserConnection {
  final String platformId;
  final String label;
  final ConnectionTier tier;
  final DateTime addedAt;
  // Tier 1
  final String? address;
  final String? chain; // 'btc' | 'evm' | 'sol'
  // Tier 2 (stored locally only — never sent to our backend)
  final String? apiKey;
  final String? apiSecret;

  const UserConnection({
    required this.platformId,
    required this.label,
    required this.tier,
    required this.addedAt,
    this.address,
    this.chain,
    this.apiKey,
    this.apiSecret,
  });

  Map<String, dynamic> toJson() => {
        'platformId': platformId,
        'label': label,
        'tier': tier.name,
        'addedAt': addedAt.toIso8601String(),
        'address': address,
        'chain': chain,
        'apiKey': apiKey,
        'apiSecret': apiSecret,
      };

  factory UserConnection.fromJson(Map<String, dynamic> j) => UserConnection(
        platformId: j['platformId'] as String,
        label: j['label'] as String,
        tier: ConnectionTier.values.firstWhere((t) => t.name == j['tier']),
        addedAt: DateTime.parse(j['addedAt'] as String),
        address: j['address'] as String?,
        chain: j['chain'] as String?,
        apiKey: j['apiKey'] as String?,
        apiSecret: j['apiSecret'] as String?,
      );
}

/// Catalog of every platform Float can connect to, grouped by tier.
class ConnectionService {
  static const String _storageKey = 'user_connections';

  // ---- Tier 1: address-based (self-custody / hardware wallets) ----
  static const List<PlatformConnector> addressPlatforms = [
    PlatformConnector(
      id: 'ledger', name: 'Ledger', icon: '🔐', tier: ConnectionTier.address,
      blurb: 'Paste your public receive address — works for any Ledger asset.',
      addressHints: ['btc', 'evm', 'sol'],
    ),
    PlatformConnector(
      id: 'tangem', name: 'Tangem', icon: '💳', tier: ConnectionTier.address,
      blurb: 'Paste your Tangem wallet address — read-only tracking.',
      addressHints: ['btc', 'evm', 'sol'],
    ),
    PlatformConnector(
      id: 'trezor', name: 'Trezor', icon: '🛡️', tier: ConnectionTier.address,
      blurb: 'Paste your Trezor public address.',
      addressHints: ['btc', 'evm'],
    ),
    PlatformConnector(
      id: 'metamask', name: 'MetaMask / EVM Wallet', icon: '🦊', tier: ConnectionTier.address,
      blurb: 'Any Ethereum, Base, Arbitrum, Polygon, or BSC address.',
      addressHints: ['evm'],
    ),
    PlatformConnector(
      id: 'phantom', name: 'Phantom / Solana', icon: '👻', tier: ConnectionTier.address,
      blurb: 'Any Solana wallet address.',
      addressHints: ['sol'],
    ),
    PlatformConnector(
      id: 'cryptocom_defi', name: 'Crypto.com DeFi Wallet', icon: '🔗', tier: ConnectionTier.address,
      blurb: 'Self-custody wallet — paste the public address.',
      addressHints: ['evm', 'btc', 'sol'],
    ),
    PlatformConnector(
      id: 'bitcoin_wallet', name: 'Bitcoin Wallet (any)', icon: '₿', tier: ConnectionTier.address,
      blurb: 'Any BTC address — exchange cold wallets, hardware, whatever.',
      addressHints: ['btc'],
    ),
  ];

  // ---- Tier 2: exchange API keys ----
  static const List<PlatformConnector> apiKeyPlatforms = [
    PlatformConnector(
      id: 'coinbase', name: 'Coinbase', icon: '🪙', tier: ConnectionTier.apiKey,
      blurb: 'Create a read-only API key at coinbase.com/settings/api.',
    ),
    PlatformConnector(
      id: 'kraken', name: 'Kraken', icon: '🐙', tier: ConnectionTier.apiKey,
      blurb: 'Settings → API → Generate New Key (enable "Query Funds" only).',
    ),
    PlatformConnector(
      id: 'binance', name: 'Binance', icon: '🔶', tier: ConnectionTier.apiKey,
      blurb: 'API Management → Create API → enable reading only.',
    ),
    PlatformConnector(
      id: 'binance_us', name: 'Binance.US', icon: '🇺🇸', tier: ConnectionTier.apiKey,
      blurb: 'Same flow as Binance, on binance.us.',
    ),
    PlatformConnector(
      id: 'cryptocom_exchange', name: 'Crypto.com Exchange', icon: '💎', tier: ConnectionTier.apiKey,
      blurb: 'API Management → Create new API key (read-only).',
    ),
    PlatformConnector(
      id: 'gemini', name: 'Gemini', icon: '♊', tier: ConnectionTier.apiKey,
      blurb: 'Settings → API → Create a "Primary" key with Fund status only.',
    ),
    PlatformConnector(
      id: 'okx', name: 'OKX', icon: '⭕', tier: ConnectionTier.apiKey,
      blurb: 'API → Create V5 API key with Read permission.',
    ),
    PlatformConnector(
      id: 'bybit', name: 'Bybit', icon: '⚡', tier: ConnectionTier.apiKey,
      blurb: 'API Management → Create read-only key.',
    ),
    PlatformConnector(
      id: 'kucoin', name: 'KuCoin', icon: '🟢', tier: ConnectionTier.apiKey,
      blurb: 'API Management → Create API with General (read) permission.',
    ),
    PlatformConnector(
      id: 'bitstamp', name: 'Bitstamp', icon: '🏛️', tier: ConnectionTier.apiKey,
      blurb: 'Security → API Access → read-only key.',
    ),
  ];

  // ---- Tier 3: brokerages (via Plaid/SnapTrade — requires aggregator keys) ----
  static const List<PlatformConnector> brokeragePlatforms = [
    PlatformConnector(id: 'fidelity', name: 'Fidelity', icon: '🏦', tier: ConnectionTier.brokerage, blurb: 'Stocks, ETFs, 401k — via secure aggregator.'),
    PlatformConnector(id: 'schwab', name: 'Charles Schwab', icon: '🏦', tier: ConnectionTier.brokerage, blurb: 'Brokerage + retirement accounts.'),
    PlatformConnector(id: 'vanguard', name: 'Vanguard', icon: '⛵', tier: ConnectionTier.brokerage, blurb: 'Index funds and IRAs.'),
    PlatformConnector(id: 'robinhood', name: 'Robinhood', icon: '🏹', tier: ConnectionTier.brokerage, blurb: 'Stocks, options, and crypto.'),
    PlatformConnector(id: 'etrade', name: 'E*TRADE', icon: '📈', tier: ConnectionTier.brokerage, blurb: 'Morgan Stanley brokerage.'),
    PlatformConnector(id: 'td_ameritrade', name: 'TD Ameritrade', icon: '🟩', tier: ConnectionTier.brokerage, blurb: 'Now part of Schwab — legacy accounts.'),
    PlatformConnector(id: 'webull', name: 'Webull', icon: '🐂', tier: ConnectionTier.brokerage, blurb: 'Commission-free stocks and options.'),
    PlatformConnector(id: 'interactive_brokers', name: 'Interactive Brokers', icon: '🌐', tier: ConnectionTier.brokerage, blurb: 'IBKR — global markets.'),
    PlatformConnector(id: 'merrill', name: 'Merrill Edge', icon: '🐂', tier: ConnectionTier.brokerage, blurb: 'Bank of America investing.'),
    PlatformConnector(id: 'ally', name: 'Ally Invest', icon: '💜', tier: ConnectionTier.brokerage, blurb: 'Self-directed + robo portfolios.'),
    PlatformConnector(id: 'public', name: 'Public', icon: '📣', tier: ConnectionTier.brokerage, blurb: 'Stocks, ETFs, treasuries.'),
    PlatformConnector(id: 'wealthfront', name: 'Wealthfront', icon: '📊', tier: ConnectionTier.brokerage, blurb: 'Robo-advisor + cash accounts.'),
    PlatformConnector(id: 'betterment', name: 'Betterment', icon: '🌱', tier: ConnectionTier.brokerage, blurb: 'Automated investing.'),
    PlatformConnector(id: 'm1', name: 'M1 Finance', icon: '🥧', tier: ConnectionTier.brokerage, blurb: 'Pie-based automated portfolios.'),
    PlatformConnector(id: 'sofi', name: 'SoFi Invest', icon: '🎓', tier: ConnectionTier.brokerage, blurb: 'Active + automated investing.'),
    PlatformConnector(id: 'chase', name: 'J.P. Morgan / Chase', icon: '🏛️', tier: ConnectionTier.brokerage, blurb: 'Self-directed and advisor accounts.'),
  ];

  static List<PlatformConnector> get all => [
        ...addressPlatforms,
        ...apiKeyPlatforms,
        ...brokeragePlatforms,
      ];

  static PlatformConnector? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  // ---- Persistence (local; API keys never leave the device) ----

  static Future<List<UserConnection>> loadConnections() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((j) => UserConnection.fromJson(Map<String, dynamic>.from(j))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<UserConnection> connections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(connections.map((c) => c.toJson()).toList()),
    );
  }

  static Future<void> addConnection(UserConnection connection) async {
    final existing = await loadConnections();
    existing.add(connection);
    await _saveAll(existing);
  }

  static Future<void> removeConnection(String platformId, {String? address}) async {
    var existing = await loadConnections();
    existing = existing
        .where((c) => !(c.platformId == platformId && (address == null || c.address == address)))
        .toList();
    await _saveAll(existing);
  }
}
