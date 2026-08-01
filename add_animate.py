with open("lib/features/agents/ai_agents_screen.dart", "r", encoding="utf-8") as f:
    c = f.read()

old = '          // Agent\'s Snapshot - what the agent is watching right now\n          const SizedBox(height: 10),\n          Container('
new = '          // Agent\'s Snapshot - what the agent is watching right now\n          const SizedBox(height: 10),\n          Container('.animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.05)

if old in c:
    c = c.replace(old, new)
    print("animate on snapshot")

old_row = '              return Padding(\n                padding: const EdgeInsets.symmetric(vertical: 1),\n                child: Row('
new_row = '              return Padding(\n                padding: const EdgeInsets.symmetric(vertical: 1),\n                child: Row('.animate().fadeIn()

if old_row in c:
    c = c.replace(old_row, new_row, 1)
    print("animate on activity")

with open("lib/features/agents/ai_agents_screen.dart", "w", encoding="utf-8") as f:
    f.write(c)
print("done")
