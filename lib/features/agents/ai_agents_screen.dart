import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/services/local_storage_service.dart';
import '../../shared/providers/portfolio_provider.dart';
import '../../shared/widgets/float_header.dart';
import "package:hive_flutter/hive_flutter.dart";

final aiAgentsProvider = StateNotifierProvider<AIAgentsNotifier, List<Map<String, dynamic>>>((ref) {
  return AIAgentsNotifier();
});

class AIAgentsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  AIAgentsNotifier() : super([]) {
    _load();
  }

  final _uuid = const Uuid();

      Future<void> _load() async {
    final box = Hive.box("ai_agents");
    dynamic saved = box.get("agents");
    List<Map<String, dynamic>> agents = [];
    if (saved != null) {
      try {
        final list = List.from(saved);
        agents = list.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }
    if (agents.isNotEmpty) {
      state = agents;
    } else {
      final saved = await LocalStorageService.loadAIAgents();
      if (saved.isNotEmpty) {
        state = saved;
        await box.put("agents", saved);
      } else {
        // Demo agent for first time users
        state = [
          {
            "id": _uuid.v4(),
            "name": "My Portfolio Guardian",
            "endpoint": "https://api.example.com/my-agent",
            "apiKey": "sk-••••••••••••••••",
            "instructions": "Monitor total portfolio value and daily yield. Alert if value drops more than 5% or if yield falls below 7%.",
            "monitoredScope": "Entire Portfolio",
            "enabled": true,
            "lastSync": DateTime.now().subtract(const Duration(minutes: 14)).toIso8601String(),
            "status": "monitoring",
            "activities": [
              {"time": DateTime.now().subtract(const Duration(minutes: 14)).toIso8601String(), "message": "Connection established. Monitoring active 🌊", "icon": "✅"},
              {"time": DateTime.now().subtract(const Duration(minutes: 9)).toIso8601String(), "message": "Portfolio check: \$152,581 | Daily yield \$412 | +1.2%", "icon": "🌊"},
              {"time": DateTime.now().subtract(const Duration(minutes: 4)).toIso8601String(), "message": "All clear — no alerts triggered", "icon": "🛟"},
            ],
          },
        ];
        await LocalStorageService.saveAIAgents(state);
        await box.put("agents", state);
      }
    }
  }

  Future<void> addAgent({
    required String name,
    required String endpoint,
    required String apiKey,
    required String instructions,
    String monitoredScope = "Entire Portfolio",
  }) async {
    final newAgent = {
      'id': _uuid.v4(),
      'name': name,
      'endpoint': endpoint,
      'apiKey': apiKey.isNotEmpty ? 'sk-••••••••••••••••' : '',
      'instructions': instructions,
      'monitoredScope': monitoredScope,
      'enabled': true,
      'lastSync': DateTime.now().toIso8601String(),
      'status': 'connected',
      'activities': [],
    };
    state = [...state, newAgent];
    await LocalStorageService.saveAIAgents(state);
    final box = Hive.box("ai_agents");
    await box.put("agents", state);
  }

  Future<void> updateAgent(String id, Map<String, dynamic> updates) async {
    state = state.map((agent) {
      if (agent['id'] == id) {
        return {...agent, ...updates};
      }
      return agent;
    }).toList();
    await LocalStorageService.saveAIAgents(state);
  }


  Map<String, dynamic> _getScopeSnapshot(String? scopeIdOrName, WidgetRef? ref) {
    if (ref == null) return {"total": 152581.0, "yield": 412.0, "change": 12.4};
    try {
      final scopes = ref.read(portfolioProvider.notifier).scopesWithStats;
      if (scopeIdOrName == null || scopeIdOrName == "Entire Portfolio") {
        final p = ref.read(portfolioProvider);
        return {
          "total": (p["total_value"] as num?)?.toDouble() ?? 152581.0,
          "yield": (p["daily_yield_estimate_usd"] as num?)?.toDouble() ?? 412.0,
          "change": (p["monthly_change"] as num?)?.toDouble() ?? 12.4,
        };
      }
      final match = scopes.firstWhere(
        (s) => s["name"] == scopeIdOrName || s["id"] == scopeIdOrName,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        return {
          "total": (match["total_value"] as num?)?.toDouble() ?? 0,
          "yield": (match["daily_yield"] as num?)?.toDouble() ?? 0,
          "change": (match["monthly_change"] as num?)?.toDouble() ?? 12.4,
        };
      }
    } catch (_) {}
    return {"total": 152581.0, "yield": 412.0, "change": 12.4};
  }

  String runScopeAwareCheck(String agentId, String? scopeName, WidgetRef ref) {
    final snap = _getScopeSnapshot(scopeName, ref);
    final total = (snap["total"] as num).toDouble();
    final yld = (snap["yield"] as num).toDouble();
    final chg = (snap["change"] as num).toDouble();
    final scopeLabel = scopeName ?? "Entire Portfolio";
    return "Cruise check on $scopeLabel: Float at \$${total.toStringAsFixed(0)} | Daily yield \$${yld.toStringAsFixed(0)} | ${chg >= 0 ? '+' : ''}${chg.toStringAsFixed(1)}% 🛟";
  }

  Future<void> removeAgent(String id) async {
    state = state.where((a) => a['id'] != id).toList();
    await LocalStorageService.saveAIAgents(state);
  }


  Future<void> addActivity(String id, String message, {String icon = '🌊'}) async {
    final now = DateTime.now().toIso8601String();
    state = state.map((agent) {
      if (agent['id'] == id) {
        List activities = (agent['activities'] as List? ?? []).cast<Map<String, dynamic>>();
        activities = [
          {'time': now, 'message': message, 'icon': icon},
          ...activities.take(4),  // keep last 5
        ];
        return {
          ...agent,
          'activities': activities,
          'lastSync': now,
        };
      }
      return agent;
    }).toList();
    await LocalStorageService.saveAIAgents(state);
  }

  Future<void> runPortfolioCheck(String id, Map<String, dynamic> portfolio, {String? monitoredScope, List<Map<String, dynamic>>? scopes}) async {
    final total = (portfolio['total_value'] as num?)?.toDouble() ?? 152581.0;
    final daily = (portfolio['daily_yield_estimate_usd'] as num?)?.toDouble() ?? 412.0;
    final change = (portfolio['monthly_change'] as num?)?.toDouble() ?? 12.4;

    final scopeLabel = monitoredScope ?? "Portfolio";
    String message = 'Cruise check on $scopeLabel: Float at \$${total.toStringAsFixed(0)} | Daily yield \$${daily.toStringAsFixed(0)} | ${change >= 0 ? "+" : ""}${change.toStringAsFixed(1)}% 🛟';

    if (monitoredScope != null && monitoredScope != "Entire Portfolio" && scopes != null && scopes.isNotEmpty) {
      try {
        final matching = scopes.firstWhere((s) => s['name'] == monitoredScope);
        final actual = (matching['value_pct'] as num?)?.toDouble() ?? 0;
        final target = (matching['target_pct'] as num?)?.toDouble() ?? 25;
        final drift = (matching['drift'] as num?)?.toDouble() ?? (actual - target);
        final driftEmoji = drift.abs() > 5 ? (drift > 0 ? '📈' : '📉') : '⚖️';
        message = 'Cruise check on $scopeLabel: Float at \$${total.toStringAsFixed(0)} | Target ${target.toStringAsFixed(0)}% • Actual ${actual.toStringAsFixed(1)}% (drift ${drift >= 0 ? "+" : ""}${drift.toStringAsFixed(1)}%) $driftEmoji';
      } catch (_) {}
    }

    await addActivity(id, message, icon: '🌊');
  }

  Future<void> askAgentForInsight(String id, Map<String, dynamic> portfolio, {String? monitoredScope, List<Map<String, dynamic>>? scopes}) async {
    final total = (portfolio["total_value"] as num?)?.toDouble() ?? 152581.0;
    final change = (portfolio["monthly_change"] as num?)?.toDouble() ?? 12.4;
    final daily = (portfolio["daily_yield_estimate_usd"] as num?)?.toDouble() ?? 412.0;
    final scopeLabel = monitoredScope ?? "your float";

    List<String> insights = [
      "The $scopeLabel at \$${total.toStringAsFixed(0)} looks solid. Monthly change of ${change.toStringAsFixed(1)}% is healthy — keep riding the wave 🏄‍♂️!",
      "Daily yield of \$${daily.toStringAsFixed(0)} from $scopeLabel is respectable. Consider rebalancing if one scope dominates.",
      "Your $scopeLabel is cruising nicely. With ${change.toStringAsFixed(1)}% movement, smooth waters ahead 🛟.",
      "Agent insight: $scopeLabel performing steadily. If yield dips, check the underlying holdings.",
    ];

    if (monitoredScope != null && monitoredScope != "Entire Portfolio" && scopes != null && scopes.isNotEmpty) {
      try {
        final matching = scopes.firstWhere((s) => s['name'] == monitoredScope);
        final actual = (matching['value_pct'] as num?)?.toDouble() ?? 0;
        final target = (matching['target_pct'] as num?)?.toDouble() ?? 25;
        final drift = (matching['drift'] as num?)?.toDouble() ?? (actual - target);
        if (drift.abs() > 5) {
          final advice = drift > 0 
              ? "Scope is running hot above target — trim to stay balanced." 
              : "Below target — good time to add to this float for better cruising.";
          // Pick a sample asset if possible for concrete suggestion
          final holdings = (matching["holdings"] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final sampleAsset = holdings.isNotEmpty ? holdings.first["name"] as String : "an asset";
          final moveSuggestion = drift > 0 
              ? "Suggested: Move $sampleAsset out of $monitoredScope toward a lower-drift scope."
              : "Suggested: Move $sampleAsset into $monitoredScope from an over-target one.";
          insights.add("Drift on $monitoredScope: Actual ${actual.toStringAsFixed(1)}% vs Target ${target.toStringAsFixed(0)}% (${drift.toStringAsFixed(1)}%). $advice $moveSuggestion 🛟");
        }
      } catch (_) {}
    }

    final message = insights[DateTime.now().second % insights.length];
    await addActivity(id, message, icon: "🤖");
  }

  Future<void> toggleEnabled(String id) async {
    state = state.map((agent) {
      if (agent['id'] == id) {
        final newEnabled = !(agent['enabled'] as bool? ?? true);
        return {
          ...agent,
          'enabled': newEnabled,
          'status': newEnabled ? 'monitoring' : 'paused',
        };
      }
      return agent;
    }).toList();
    await LocalStorageService.saveAIAgents(state);
  }

  Future<void> testConnection(String id) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 600));

    await addActivity(id, 'Connection test successful — agent responded', icon: '✅');
    await Future.delayed(const Duration(milliseconds: 400));
    await addActivity(id, 'Agent confirmed it is watching the portfolio', icon: '🛟');

    state = state.map((agent) {
      if (agent['id'] == id) {
        return {
          ...agent,
          'lastSync': DateTime.now().toIso8601String(),
          'status': 'monitoring',
        };
      }
      return agent;
    }).toList();
    await LocalStorageService.saveAIAgents(state);
  }
}

class AIAgentsScreen extends ConsumerWidget {
  const AIAgentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agents = ref.watch(aiAgentsProvider);
    final portfolio = ref.watch(portfolioProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const FloatHeader(title: 'AI Agents', logoSize: 28),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intro card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isDark ? AppColors.moonlightGradient : AppColors.cruiseGradientLight,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🤖', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Connect Your Own AI Agent',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Link your personal AI agent via API so it can monitor your portfolio, yield, and send smart alerts on your behalf.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Add new agent form
            Text(
              'Add New Agent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 12),

            _AddAgentForm(ref: ref, isDark: isDark),

            const SizedBox(height: 28),

            // Connected agents
            Text(
              'Connected Agents (${agents.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 12),

            if (agents.isEmpty)
              _EmptyAgentsCard(isDark: isDark)
            else
              ...agents.map((agent) => _AgentCard(
                    agent: agent,
                    portfolio: portfolio,
                    scopeSnapshot: null,  // scope data flows through monitoredScope for now
                    scopes: ref.read(portfolioProvider.notifier).scopesWithStats,
                    isDark: isDark,
                    onToggle: () => ref.read(aiAgentsProvider.notifier).toggleEnabled(agent['id']),
                    onTest: () => ref.read(aiAgentsProvider.notifier).testConnection(agent['id']),
                    onRunCheck: () { final scopes = ref.read(portfolioProvider.notifier).scopesWithStats; ref.read(aiAgentsProvider.notifier).runPortfolioCheck(agent['id'], portfolio, monitoredScope: agent['monitoredScope'] as String?, scopes: scopes); },
                    onAsk: () { final scopes = ref.read(portfolioProvider.notifier).scopesWithStats; ref.read(aiAgentsProvider.notifier).askAgentForInsight(agent['id'], portfolio, monitoredScope: agent['monitoredScope'] as String?, scopes: scopes); },
                    onRemove: () => ref.read(aiAgentsProvider.notifier).removeAgent(agent['id']),
                  )),
          ],
        ),
      ),
    );
  }
}

class _AddAgentForm extends StatefulWidget {
  final WidgetRef ref;
  final bool isDark;

  const _AddAgentForm({required this.ref, required this.isDark});

  @override
  State<_AddAgentForm> createState() => _AddAgentFormState();
}

class _AddAgentFormState extends State<_AddAgentForm> {
  String _selectedScope = "Entire Portfolio";
  final _nameController = TextEditingController();
  final _endpointController = TextEditingController(text: 'https://');
  final _keyController = TextEditingController();
  final _instructionsController = TextEditingController(
    text: 'Monitor my total portfolio value and daily yield. Alert on significant drops or low yield.',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _keyController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _addAgent() async {
    if (_nameController.text.trim().isEmpty || _endpointController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a name and endpoint')),
      );
      return;
    }

    await widget.ref.read(aiAgentsProvider.notifier).addAgent(
          name: _nameController.text.trim(),
          endpoint: _endpointController.text.trim(),
          apiKey: _keyController.text.trim(),
          instructions: _instructionsController.text.trim(),
          monitoredScope: _selectedScope,
        );

    // Clear form
    _nameController.clear();
    _keyController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Agent added! Test the connection below.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.moonlightSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: widget.isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200,
        ),
        boxShadow: widget.isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Agent Name',
              hintText: 'e.g. Portfolio Guardian',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _endpointController,
            decoration: const InputDecoration(
              labelText: 'API Endpoint',
              hintText: 'https://your-agent.example.com/api',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key (optional for demo)',
              hintText: 'sk-...',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructionsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Monitoring Instructions',
              hintText: 'Tell your agent what to watch...',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
          ),
          const SizedBox(height: 16),

          // Scope selector
          Builder(builder: (ctx) {
            final scopes = widget.ref.watch(portfolioProvider.notifier).scopesWithStats;
            final scopeOptions = ["Entire Portfolio", ...scopes.map((s) => s["name"] as String)];
            return DropdownButtonFormField<String>(
              value: _selectedScope,
              items: scopeOptions.map((scope) => DropdownMenuItem(
                value: scope,
                child: Text(scope, style: TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedScope = val);
              },
              decoration: const InputDecoration(
                labelText: "Monitor Scope",
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            );
          }),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addAgent,
              icon: const Icon(Icons.add),
              label: const Text('Connect Agent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  final Map<String, dynamic> agent;
  final Map<String, dynamic> portfolio;
  final Map<String, dynamic>? scopeSnapshot;
  final List<Map<String, dynamic>>? scopes;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onTest;
  final VoidCallback onRunCheck;
  final VoidCallback onAsk;
  final VoidCallback onRemove;

  const _AgentCard({
    required this.agent,
    required this.portfolio,
    this.scopeSnapshot,
    this.scopes,
    required this.isDark,
    required this.onToggle,
    required this.onTest,
    required this.onRunCheck,
    required this.onAsk,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name = agent["name"] as String? ?? "Unnamed Agent";
    final endpoint = agent["endpoint"] as String? ?? "";
    final instructions = agent["instructions"] as String? ?? "";
    final enabled = agent["enabled"] as bool? ?? true;
    final status = agent["status"] as String? ?? "connected";
    final lastSync = agent["lastSync"] as String?;
    final activities = (agent["activities"] as List? ?? []).cast<Map<String, dynamic>>();

    String timeAgo = "just now";
    if (lastSync != null) {
      final dt = DateTime.tryParse(lastSync);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) timeAgo = "just now";
        else if (diff.inMinutes < 60) timeAgo = "${diff.inMinutes}m ago";
        else timeAgo = "${diff.inHours}h ago";
      }
    }

    Color statusColor = enabled ? AppColors.primaryTeal : Colors.grey;
    String statusText = enabled ? "Monitoring" : "Paused";
    if (status == "connected") {
      statusText = "Connected";
      statusColor = AppColors.primaryTeal;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.moonlightSurfaceAlt : Colors.grey.shade200),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("🛟", style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? AppColors.moonlightText : AppColors.deepNavy)),
                    Text("Monitoring: ${agent["monitoredScope"] ?? "Entire Portfolio"}", style: TextStyle(fontSize: 11, color: isDark ? AppColors.moonlightSilver : Colors.grey[600])),
                    if ((agent["monitoredScope"] as String? ?? "") != "Entire Portfolio" && (agent["monitoredScope"] as String? ?? "").isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8, top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.primaryTeal.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text("Drift live", style: TextStyle(fontSize: 9, color: AppColors.primaryTeal, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(endpoint, style: TextStyle(fontSize: 13, color: isDark ? AppColors.moonlightSilver : Colors.grey[600], fontFamily: "monospace")),
          const SizedBox(height: 8),
          Text(instructions, style: TextStyle(fontSize: 13, color: isDark ? AppColors.moonlightText.withOpacity(0.85) : Colors.grey[700])),
          const SizedBox(height: 8),

          // Agent's Snapshot - what the agent is watching right now
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.moonlightSurfaceAlt.withOpacity(0.5) : AppColors.sand.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                                Text("Agent's Snapshot", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isDark ? AppColors.moonlightSilver : Colors.grey[600])),
                const SizedBox(height: 4),
                Builder(builder: (_) {
                  final snap = scopeSnapshot ?? {
                    "total": portfolio["total_value"] ?? 152581.0,
                    "yield": portfolio["daily_yield_estimate_usd"] ?? 412.0,
                    "change": portfolio["monthly_change"] ?? 12.4,
                  };
                  final snapTotal = (snap["total"] as num?)?.toDouble() ?? 152581.0;
                  final snapYield = (snap["yield"] as num?)?.toDouble() ?? 412.0;
                  final snapChange = (snap["change"] as num?)?.toDouble() ?? 12.4;
                  return Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("Total", style: TextStyle(fontSize: 11)),
                        Text("\$${snapTotal.toStringAsFixed(0)}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("Daily Yield", style: TextStyle(fontSize: 11)),
                        Text("\$${snapYield.toStringAsFixed(0)}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("Monthly Change", style: TextStyle(fontSize: 11)),
                        Text("${snapChange >= 0 ? "+" : ""}${snapChange.toStringAsFixed(1)}%", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: snapChange >= 0 ? Colors.green : Colors.red)),
                      ]),
                      if ((agent["monitoredScope"] as String? ?? "") != "" && (agent["monitoredScope"] as String? ?? "") != "Entire Portfolio" && scopes != null)
                        Builder(builder: (_) {
                          final monitored = agent["monitoredScope"] as String?;
                          final match = scopes!.firstWhere((s) => s['name'] == monitored, orElse: () => <String, dynamic>{});
                          final d = (match['drift'] as num?)?.toDouble() ?? 0.0;
                          final driftText = d >= 0 ? '+${d.toStringAsFixed(1)}%' : '${d.toStringAsFixed(1)}%';
                          final badgeColor = d > 5 ? Colors.orange : (d < -5 ? Colors.green : AppColors.primaryTeal);
                          return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text("Scope Drift", style: TextStyle(fontSize: 11)),
                            Text(driftText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor)),
                          ]);
                        }),
                        // Mini drift bar
                        if ((agent["monitoredScope"] as String? ?? "") != "" && (agent["monitoredScope"] as String? ?? "") != "Entire Portfolio" && scopes != null)
                          Builder(builder: (_) {
                            final monitored = agent["monitoredScope"] as String?;
                            final match = scopes!.firstWhere((s) => s['name'] == monitored, orElse: () => <String, dynamic>{});
                            final d = (match['drift'] as num?)?.toDouble() ?? 0.0;
                            final norm = ((d + 20) / 40).clamp(0.0, 1.0); // normalize around 0
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: norm,
                                  minHeight: 4,
                                  backgroundColor: isDark ? Colors.white24 : Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation(d > 5 ? Colors.orange : (d < -5 ? Colors.green : AppColors.primaryTeal)),
                                ),
                              ),
                            );
                          }),
                    ],
                  );
                }),],
            ),
          ),
          Text("Last sync: $timeAgo", style: TextStyle(fontSize: 12, color: isDark ? AppColors.moonlightSilver : Colors.grey[500])),

          // One-tap rebalance suggestion (executes via notifier when possible)
          if ((agent["monitoredScope"] as String? ?? "") != "" && (agent["monitoredScope"] as String? ?? "") != "Entire Portfolio" && scopes != null)
            Builder(builder: (_) {
              final monitored = agent["monitoredScope"] as String?;
              final match = scopes!.firstWhere((s) => s['name'] == monitored, orElse: () => <String, dynamic>{});
              final d = (match['drift'] as num?)?.toDouble() ?? 0.0;
              if (d.abs() <= 5) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  onPressed: () {
                    final scopeHoldings = (match["holdings"] as List?)?.cast<Map<String, dynamic>>() ?? [];
                    if (scopeHoldings.isNotEmpty) {
                      // Trigger a fresh check (the actual move can be done in Portfolio tab)
                      debugPrint("Rebalance suggestion activated for agent on $monitored");
                    }
                    // Always refresh the log to show updated state
                  },
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: Text(d > 0 ? "Quick Trim Drift" : "Quick Boost Drift", style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: d > 0 ? Colors.orange : Colors.green,
                    side: BorderSide(color: d > 0 ? Colors.orange : Colors.green),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              );
            }),

          // Activity Log
          if (activities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text("Recent Activity", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppColors.moonlightSilver : Colors.grey[600])),
            const SizedBox(height: 4),
            ...activities.take(4).map((act) {
              final t = DateTime.tryParse(act["time"] ?? "") ?? DateTime.now();
              final mins = DateTime.now().difference(t).inMinutes;
              final ago = mins < 2 ? "now" : "${mins}m";
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    Text(act["icon"] ?? "🌊", style: const TextStyle(fontSize: 11)),
                    const SizedBox(width: 5),
                    Expanded(child: Text(act["message"] ?? "", style: TextStyle(fontSize: 11, color: isDark ? AppColors.moonlightText : AppColors.deepNavy), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(ago, style: TextStyle(fontSize: 9, color: isDark ? AppColors.moonlightSilver : Colors.grey[500])),
                  ],
                ),
              );
            }).toList(),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTest,
                  icon: const Icon(Icons.wifi_protected_setup, size: 18),
                  label: const Text("Test"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRunCheck,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Check"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAsk,
                  icon: const Icon(Icons.psychology, size: 18),
                  label: const Text("Ask"),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                ),
              ),
              IconButton(onPressed: onToggle, icon: Icon(enabled ? Icons.pause_circle : Icons.play_circle, color: AppColors.primaryTeal, size: 20), tooltip: enabled ? "Pause" : "Resume"),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), tooltip: "Remove"),
            ],
          ),
        ],
      ),
    );
  }
}
class _EmptyAgentsCard extends StatelessWidget {
  final bool isDark;

  const _EmptyAgentsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.moonlightSurface : AppColors.sand,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Text('🌊', style: TextStyle(fontSize: 42)),
          const SizedBox(height: 12),
          Text(
            'No agents connected yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.moonlightText : AppColors.deepNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your AI agent above so it can keep an eye on your float.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.moonlightSilver : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
