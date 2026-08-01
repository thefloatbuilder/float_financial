with open("lib/features/agents/ai_agents_screen.dart", "r", encoding="utf-8") as f:
    c = f.read()

old_snap = """          // Agent's Snapshot - what the agent is watching right now
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.moonlightSurfaceAlt.withOpacity(0.5) : AppColors.sand.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column("""

new_snap = """          // Agent's Snapshot - what the agent is watching right now
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.moonlightSurfaceAlt.withOpacity(0.5) : AppColors.sand.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(""".animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.1)"""

if old_snap in c:
    c = c.replace(old_snap, new_snap)
    print("Added animate to snapshot")

old_row = """              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row("""

new_row = """              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(""".animate().fadeIn()"""

if old_row in c:
    c = c.replace(old_row, new_row, 1)
    print("Added fade to activity row")

with open("lib/features/agents/ai_agents_screen.dart", "w", encoding="utf-8") as f:
    f.write(c)
print("Animate edits complete")
