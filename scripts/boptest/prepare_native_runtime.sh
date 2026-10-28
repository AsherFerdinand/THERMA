#!/usr/bin/env bash
# Supply the real legacy Fortran ABI, without changing the FMU/system libraries.
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
native_dir="$project_root/outputs/boptest/native"
mkdir -p "$native_dir"
image='ubuntu@sha256:152dc042452c496007f07ca9127571cb9c29697f42acbfad72324b2bb2e43c98'
container_id=$(docker create "$image" sh -c 'apt-get update && apt-get install -y --no-install-recommends libgfortran4=7.5.0-3ubuntu1~18.04 && dpkg-query -W libgfortran4')
trap 'docker rm -f "$container_id" >/dev/null' EXIT
docker start -a "$container_id"
test "$(docker inspect -f '{{.State.ExitCode}}' "$container_id")" = 0
docker cp "$container_id:/usr/lib/x86_64-linux-gnu/libgfortran.so.4.0.0" "$native_dir/libgfortran.so.4"
printf '%s  %s\n' 'd87b8024db66386051efbabb393cce9b8a580bb9be6e461043f74fd7653c9894' "$native_dir/libgfortran.so.4" | sha256sum --check
printf 'Native library prepared. Set LD_LIBRARY_PATH to %s before running Python.\n' "$native_dir"
cat > "$native_dir/provenance.json" <<'JSON'
{
  "image": "ubuntu@sha256:152dc042452c496007f07ca9127571cb9c29697f42acbfad72324b2bb2e43c98",
  "package": "libgfortran4",
  "version": "7.5.0-3ubuntu1~18.04",
  "installed_with": "APT signed Ubuntu repository metadata and package verification",
  "library_sha256": "d87b8024db66386051efbabb393cce9b8a580bb9be6e461043f74fd7653c9894"
}
JSON
