import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:float_financial/shared/services/bittensor_service.dart';
import 'package:float_financial/shared/services/local_storage_service.dart';

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, Map<String, dynamic>>((ref) => PortfolioNotifier());

class PortfolioNotifier extends StateNotifier<Map<String, dynamic>> {
  PortfolioNotifier() : super({
    'total_value': 152581.0,
    'total_stake': 142.5,
    'daily_yield_estimate_usd': 412.0,
    'monthly_change': 12.4,
    'apy': 8.7,
    'last_updated': DateTime.now().toIso8601String(),
    'is_live': false,
    'source': 'demo',
    'coldkey_data': {},
    'roth_ira': {
      'btc_amount': 0.07398868,
      'xrp_amount': 808.88,
      'total_usd': 5528.68,
    },
    'holdings': [
      {'name': 'Coldkey TAO', 'value': 130000.0, 'color': 0xFF14B8A6, 'source': 'Coldkey'},
      {'name': 'ROTH IRA', 'value': 5528.68, 'color': 0xFFF97316, 'source': 'Manual'},
      {'name': 'BTC', 'value': 5200.0, 'color': 0xFFF59E0B, 'source': 'Coinbase'},
      {'name': 'XRP', 'value': 4581.0, 'color': 0x3B82F6, 'source': 'Kraken'},
      {'name': 'ETH', 'value': 3019.0, 'color': 0x8B5CF6, 'source': 'Binance'},
    ],
    'custom_scopes': [],
  }) {
    loadPortfolio();
    // Seed demo exchange scopes
    if ((state["custom_scopes"] as List?)?.isEmpty ?? true) {
      createExchangeScope("Coinbase", ["BTC", "ETH"]);
      createExchangeScope("Kraken", ["XRP", "BTC"]);
    }
  }

  static const Map<String, Map<String, dynamic>> exchangeMeta = {
    "Coinbase": {"icon": "🪙", "color": 0xFF0052FF},
    "Kraken": {"icon": "🐙", "color": 0xFF5741D9},
    "Binance": {"icon": "🔶", "color": 0xFFF0B90B},
    "Coldkey Wallet": {"icon": "🛟", "color": 0xFF14B8A6},
  };

  Future<void> _loadScopes() async {
    final saved = await LocalStorageService.loadCustomScopes();
    if (saved.isNotEmpty) {
      state = {...state, "custom_scopes": saved};
    }
  }

  Future<void> _saveScopes() async {
    final scopes = (state["custom_scopes"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    await LocalStorageService.saveCustomScopes(scopes);
  }

  Future<void> loadPortfolio() async {
    final stored = await LocalStorageService.loadROTH();
    if (stored != null) {
      // Check if stored data has old XRP amount — force update to real values
      if (stored['xrp_amount'] != 808.88) {
        final updated = {
          'btc_amount': 0.07398868,
          'xrp_amount': 808.88,
          'total_usd': 5528.68,
        };
        state = {...state, 'roth_ira': updated};
        await LocalStorageService.saveROTH(updated);
      } else {
        state = {...state, 'roth_ira': stored};
      }
    }
    await refreshColdkeyData();
    await _loadScopes();
  }

  Future<void> refreshColdkeyData() async {
    final fresh = await BittensorService().fetchColdkeyData();

    final newState = {
      ...state,
      'coldkey_data': fresh,
      'total_stake': fresh['total_stake'],
      'daily_yield_estimate_usd': fresh['daily_yield_estimate_usd'],
      'monthly_change': fresh['monthly_change'],
      'apy': fresh['apy'],
      'last_updated': fresh['last_updated'],
      'is_live': fresh['is_live'],
      'source': fresh['source'],
    };

    await LocalStorageService.saveSnapshot({
      'total_value': newState['total_value'] ?? 152581.0,
      'monthly_change': fresh['monthly_change'],
      'daily_yield': fresh['daily_yield_estimate_usd'],
      'is_live': fresh['is_live'],
      'saved_at': DateTime.now().toIso8601String(),
    });

    state = newState;
  }

  void createCustomScope(String name, List<String> assetNames, {double targetPct = 25.0}) {
    final current = List<Map<String, dynamic>>.from(state["custom_scopes"] ?? []);
    final holdings = (state["holdings"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final scopeHoldings = holdings.where((h) => assetNames.contains(h["name"])).toList();
    final total = scopeHoldings.fold<double>(0.0, (sum, h) => sum + (h["value"] as num).toDouble());
    current.add({
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": name,
      "asset_names": assetNames,
      "holdings": scopeHoldings,
      "total_value": total,
      "target_pct": targetPct,
    });
    state = {...state, "custom_scopes": current};
    _saveScopes();
  }

  void createExchangeScope(String exchange, List<String> assetNames) {
    final scopeName = "$exchange Scope";
    // Tag assets with source
    final holdings = List<Map<String, dynamic>>.from(state["holdings"] ?? []);
    final updatedHoldings = holdings.map((h) {
      if (assetNames.contains(h["name"])) {
        return {...h, "source": exchange};
      }
      return h;
    }).toList();
    state = {...state, "holdings": updatedHoldings};

    createCustomScope(scopeName, assetNames);
  }

  void editCustomScope(String id, {String? newName, List<String>? newAssetNames, double? targetPct}) {
    final current = List<Map<String, dynamic>>.from(state["custom_scopes"] ?? []);
    final idx = current.indexWhere((s) => s["id"] == id);
    if (idx < 0) return;

    final scope = Map<String, dynamic>.from(current[idx]);
    if (newName != null) scope["name"] = newName;
    if (newAssetNames != null) {
      final holdings = (state["holdings"] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final scopeHoldings = holdings.where((h) => newAssetNames.contains(h["name"])).toList();
      final total = scopeHoldings.fold<double>(0.0, (sum, h) => sum + (h["value"] as num).toDouble());
      scope["asset_names"] = newAssetNames;
      scope["holdings"] = scopeHoldings;
      scope["total_value"] = total;
    }
    if (targetPct != null) {
      scope["target_pct"] = targetPct;
    }
    current[idx] = scope;
    state = {...state, "custom_scopes": current};
    _saveScopes();
  }

  void deleteCustomScope(String id) {
    final current = List<Map<String, dynamic>>.from(state["custom_scopes"] ?? []);
    current.removeWhere((s) => s["id"] == id);
    state = {...state, "custom_scopes": current};
    _saveScopes();
  }

  Future<void> simulateImport(String exchange, String walletAddress, String apiKey) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final meta = exchangeMeta[exchange] ?? {"icon": "💼", "color": 0xFF14B8A6};
    List<String> assetNames = [];

    // Use wallet address to vary the imported assets for more realism
    final addr = walletAddress.toLowerCase();
    if (exchange == "Coinbase") {
      assetNames = addr.contains("a") || addr.endsWith("e") ? ["BTC", "ETH"] : ["BTC"];
    } else if (exchange == "Kraken") {
      assetNames = addr.contains("7") ? ["XRP", "BTC", "ETH"] : ["XRP", "BTC"];
    } else if (exchange == "Binance") {
      assetNames = ["ETH", "BTC"];
    } else {
      assetNames = ["Coldkey TAO"];
    }

    final currentHoldings = List<Map<String, dynamic>>.from(state["holdings"] ?? []);
    for (final name in assetNames) {
      if (!currentHoldings.any((h) => h["name"] == name)) {
        double val = 1800.0 + (assetNames.indexOf(name) * 650);
        if (addr.length > 10) val += (addr.hashCode % 1200);
        currentHoldings.add({
          "name": name,
          "value": val,
          "color": meta["color"],
          "source": exchange,
        });
      }
    }
    state = {...state, "holdings": currentHoldings};

    createExchangeScope(exchange, assetNames);
  }


  List<Map<String, dynamic>> get allCustomScopes => (state["custom_scopes"] as List?)?.cast<Map<String, dynamic>>() ?? [];

  List<Map<String, dynamic>> get scopesWithStats {
    final scopes = (state["custom_scopes"] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final totalValue = (state["total_value"] as num?)?.toDouble() ?? 152581.0;
    final totalYield = (state["daily_yield_estimate_usd"] as num?)?.toDouble() ?? 412.0;
    final monthlyChange = (state["monthly_change"] as num?)?.toDouble() ?? 12.4;

    return scopes.map((scope) {
      final scopeValue = (scope["total_value"] as num?)?.toDouble() ?? 0.0;
      final valuePct = totalValue > 0 ? (scopeValue / totalValue) * 100 : 0;
      final scopeYield = totalYield * (scopeValue / totalValue);
      final targetPct = (scope["target_pct"] as num?)?.toDouble() ?? 25.0;
      final drift = valuePct - targetPct;
      return {
        ...scope,
        "value_pct": valuePct,
        "daily_yield": scopeYield,
        "monthly_change": monthlyChange,
        "target_pct": targetPct,
        "drift": drift,
      };
    }).toList();
  }


  void moveAssetToScope(String assetName, String? targetScopeId) {
    final currentHoldings = List<Map<String, dynamic>>.from(state["holdings"] ?? []);
    final scopes = List<Map<String, dynamic>>.from(state["custom_scopes"] ?? []);

    // Remove from any existing scope
    for (var scope in scopes) {
      final holdingsList = (scope["holdings"] as List?)?.cast<Map<String, dynamic>>() ?? [];
      scope["holdings"] = holdingsList.where((h) => h["name"] != assetName).toList();
      scope["total_value"] = (scope["holdings"] as List).fold<double>(0.0, (sum, h) => sum + (h["value"] as num).toDouble());
      scope["asset_names"] = (scope["holdings"] as List).map((h) => h["name"]).toList();
    }

    if (targetScopeId != null) {
      final target = scopes.firstWhere((s) => s["id"] == targetScopeId, orElse: () => {});
      if (target.isNotEmpty) {
        final asset = currentHoldings.firstWhere((h) => h["name"] == assetName, orElse: () => {});
        if (asset.isNotEmpty) {
          final targetHoldings = List<Map<String, dynamic>>.from(target["holdings"] ?? []);
          if (!targetHoldings.any((h) => h["name"] == assetName)) {
            targetHoldings.add(asset);
          }
          target["holdings"] = targetHoldings;
          target["total_value"] = targetHoldings.fold<double>(0.0, (sum, h) => sum + (h["value"] as num).toDouble());
          target["asset_names"] = targetHoldings.map((h) => h["name"]).toList();
        }
      }
    }

    state = {...state, "custom_scopes": scopes};
    _saveScopes();
  }

  void updateROTH(Map<String, dynamic> rothData) {
    state = {...state, 'roth_ira': rothData};
    LocalStorageService.saveROTH(rothData);
  }
}

final coldkeyRefreshProvider = Provider((ref) => ref.watch(portfolioProvider.notifier).refreshColdkeyData);
final coldkeyLastSyncProvider = Provider((ref) => ref.watch(portfolioProvider)['last_updated']);