#!/usr/bin/env bash
# PBL6: Export the ACTUAL ROS 2 workspace source from WSL2 to this branch.
set -euo pipefail
WS="${1:-$HOME/agv_mecanum_ws}"
if [[ ! -d "$WS/src" ]]; then
  echo "ERROR: Workspace source folder missing: $WS/src" >&2; exit 1
fi
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
if [[ "$(git branch --show-current)" != "pbl6-ros2-gazebo-backup" ]]; then
  echo "ERROR: Switch to branch pbl6-ros2-gazebo-backup before exporting." >&2; exit 1
fi
mkdir -p ros2_ws/src
# Copy actual tested files, including URDF, meshes, launch, RViz and future Nav2 packages.
cp -a "$WS/src/." ros2_ws/src/
# Remove temporary files ONLY from the GitHub work copy, never the WSL workspace.
find ros2_ws/src -type d \( -name __pycache__ -o -name .git -o -name .pytest_cache \) -prune -exec rm -rf {} +
find ros2_ws/src -type f \( -name '*.pyc' -o -name '*.before_mesh_fix' -o -name '*.before_visual_test' -o -name '*.before_stage1b_fix' -o -name '*.urdf.backup' \) -delete
cat > ros2_ws/README.md <<'EOF'
# PBL6 ROS 2 Workspace Source

This folder is an export of `~/agv_mecanum_ws/src` from the user's WSL2 Ubuntu 22.04 environment.

- ROS 2 Humble
- `mecanum_description`: robot URDF, SolidWorks meshes, RViz
- `mecanum_simulation`: Gazebo Classic simulation and `/cmd_vel` testing
- Other folders are copied only if present in local `src`.
- Nav2 mapping, localization, and planning are **not claimed as complete**.

Build on Ubuntu 22.04 with ROS 2 Humble after installing package dependencies:

```bash
mkdir -p ~/agv_mecanum_ws/src
cp -a ros2_ws/src/. ~/agv_mecanum_ws/src/
cd ~/agv_mecanum_ws
source /opt/ros/humble/setup.bash
colcon build --symlink-install
source install/setup.bash
```

Do not commit `build/`, `install/`, `log/`, or secrets. This project still requires hardware, safety, and Nav2 verification.
EOF
cat > .gitignore <<'EOF'
**/build/
**/install/
**/log/
**/__pycache__/
**/*.pyc
**/.pytest_cache/
*.before_mesh_fix
*.before_visual_test
*.before_stage1b_fix
*.urdf.backup
.env
*.pem
*.key
EOF
git add .gitignore ros2_ws
git status --short
echo "Ready to commit. Review the files, then:"
echo "  git commit -m 'Backup PBL6 ROS2 Gazebo workspace from WSL2'"
echo "  git push -u origin pbl6-ros2-gazebo-backup"
