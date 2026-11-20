"""Fixtures du test d'acceptation classifier_v1 (GREEN mobile 2.2.0).

Usage (depuis la racine du projet ; demande seulement numpy et Pillow) :

    python tools/vision/make_classifier_v1_fixtures.py <dossier crops_v1>

<dossier crops_v1> = ...\\FieldPlant_9classes\\crops_v1 (images de test du
projet d'entraînement). Le script :

1. copie les 11 images du tableau d'acceptation dans
   test/fixtures/classifier_v1/ (nom = <classe>_<fichier>.jpg) ;
2. écrit integration_test/classifier_v1_fixtures.g.dart (images en base64,
   le test d'acceptation tourne sur un téléphone et ne lit pas le disque
   du PC) ;
3. écrit test/fixtures/leaf_synthetic_224_pil_bilinear.rgb : redimension-
   nement de leaf_synthetic_640x480.png par Pillow (BILINEAR, qui est
   anti-crénelé comme tf.image.resize(antialias=True)), référence
   indépendante pour le prétraitement Dart.
"""
import base64
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CASES = [
    "test/0/02327_0.jpg", "test/1/01361_0.jpg", "test/2/01760_0.jpg",
    "test/3/00458_3.jpg", "test/4/00961_0.jpg", "test/5/03227_0.jpg",
    "test/6/03832_1.jpg", "test/7/00340_0.jpg", "test/8/00205_1.jpg",
    "test/5/00060_0.jpg", "test/6/00417_0.jpg",
]


def fixture_name(rel: str) -> str:
    _, cls, name = rel.split("/")
    return f"{cls}_{name}"


def main(crops_dir: Path) -> None:
    out = ROOT / "test" / "fixtures" / "classifier_v1"
    out.mkdir(parents=True, exist_ok=True)
    lines = [
        "// GÉNÉRÉ par tools/vision/make_classifier_v1_fixtures.py, ne pas modifier.",
        "// Images du test d'acceptation classifier_v1 (crops_v1/test), en base64.",
        "",
        "const Map<String, String> classifierV1Fixtures = {",
    ]
    for rel in CASES:
        src = crops_dir / rel
        dst = out / fixture_name(rel)
        shutil.copyfile(src, dst)
        b64 = base64.b64encode(dst.read_bytes()).decode("ascii")
        lines.append(f"  '{fixture_name(rel)}': '{b64}',")
    lines += ["};", ""]
    (ROOT / "integration_test").mkdir(exist_ok=True)
    (ROOT / "integration_test" / "classifier_v1_fixtures.g.dart").write_text("\n".join(lines), encoding="utf-8")

    leaf = Image.open(ROOT / "test" / "fixtures" / "leaf_synthetic_640x480.png").convert("RGB")
    ref = leaf.resize((224, 224), Image.Resampling.BILINEAR)
    (ROOT / "test" / "fixtures" / "leaf_synthetic_224_pil_bilinear.rgb").write_bytes(ref.tobytes())
    print(f"{len(CASES)} images copiées, fixtures écrites.")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(Path(sys.argv[1]))
