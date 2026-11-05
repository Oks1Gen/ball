"""Recovery after the live MCP connection stopped responding; preserve its file."""
from pathlib import Path
import bpy, traceback
HERE=Path(__file__).resolve().parent
try:
    for name in ('build_eggs.py','render_checks.py','export_stable.py'):
        p=HERE/name
        (HERE/'pipeline-status.txt').write_text(name,encoding='utf-8')
        ns={'__file__':str(p)}
        exec(compile(p.read_text(encoding='utf-8'),str(p),'exec'),ns)
    (HERE/'pipeline-status.txt').write_text('COMPLETE',encoding='utf-8')
except Exception:
    (HERE/'pipeline-status.txt').write_text(traceback.format_exc(),encoding='utf-8')
    raise
