"""Exercise production backdrop copies/bindings with a state-caching GL backend."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class NativeRenderStateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which("c++") or not shutil.which("pkg-config"):
            raise unittest.SkipTest("C++/EGL toolchain unavailable")
        flags = subprocess.run(["pkg-config", "--cflags", "--libs", "egl", "glesv2", "hyprutils", "pixman-1"],
                               capture_output=True, text=True)
        if flags.returncode:
            raise unittest.SkipTest("EGL/GLES development files unavailable")
        cls.temporary = tempfile.TemporaryDirectory(prefix="velora-render-state-")
        cls.addClassCleanup(cls.temporary.cleanup)
        directory = Path(cls.temporary.name)
        source_root = Path(os.environ.get("VELORA_RENDER_STATE_SOURCE", ROOT))
        source = (source_root / "native/hyprland/plugin.cpp").read_text()
        compat = (source_root / "native/hyprland/HyprlandCompat.hpp").read_text()
        # Compile the actual production functions, not copies of their logic.
        helpers = compat.split("// VELORA_GL_STATE_BEGIN\n")[-1].split("// VELORA_GL_STATE_END")[0] \
            if "// VELORA_GL_STATE_BEGIN\n" in compat else ""
        capture = source[source.index("bool captureClearBackdrop("):
                         source.index("SP<Render::ITexture> opticalBlurTexture(")]
        backdrop = source[source.index("SP<Render::ITexture> barBackdropTexture("):
                          source.index("struct SBarLensParameters")]
        material = source[source.index("    const auto sceneTexture = matchingKitty"):
                          source.index("    Render::GL::g_pHyprOpenGL->blend(true);", source.index("    const auto sceneTexture = matchingKitty"))]
        # Include the unit-0 selection immediately preceding that block.
        start = source.rfind("\n", 0, source.index("    const auto sceneTexture = matchingKitty") - 1)
        material = source[start:source.index("    const auto sceneTexture = matchingKitty")] + material
        unbind_start = source.index("    if (matchingKitty) {", source.index("    liquidDamage.forEachRect"))
        unbind = source[unbind_start:source.index("    VeloraCompat::scissor(ctx, nullptr);", unbind_start)]
        cache_start = source.index("    const auto previousFrame =", source.index("void hkGLDrawTex")) \
            if "    const auto previousFrame =" in source else source.index("    const bool cachedFrame = unifiedBar")
        cache = source[cache_start:source.index("    if (!captured)", cache_start)]
        hooks = ""
        for signature, end, fallback in [
            ("CRegion hkRenderPass(", "\n#endif", "CRegion hkRenderPass(Render::CRenderPass* p, Render::CRenderContext& c, const CRegion& d) { return originalPass(p,c,d); }"),
            ("SP<Render::IFramebuffer> hkBlurMain(", "\n#endif", "SP<Render::IFramebuffer> hkBlurMain(Render::IHyprRenderer* r, Render::CRenderContext& c, float s, const CRegion& d, const Render::SBlurContext& b) { return originalBlur(r,c,s,d,b); }")]:
            if signature in source:
                start = source.index(signature)
                hooks += source[start:source.index("\n}\n", start) + 3]
            else:
                hooks += fallback
        (directory / "production.inc").write_text(
            "namespace VeloraCompat {\n" + helpers + "}\n" + capture + backdrop
            + "void materialBindings(bool matchingKitty, bool useFusion, bool nativeBlur, "
              "const SP<Render::GL::CGLFramebuffer>& backdrop, "
              "const SP<Render::ITexture>& backdropTexture, SFrameFusionBackdrop* fusion, int bubbleCount = 0) {\n"
            + material + unbind + "}\n" + hooks
            + "bool captureFrame(VeloraCompat::RenderContext& ctx, const std::string& monitorName, bool topbar, bool unifiedBar) {\n"
              "const bool opticalSurface = true;\n" + cache + "return captured;\n}\n")
        cls.binary = directory / "render-state"
        compiled = subprocess.run(["c++", "-std=c++20", "-I", str(directory),
                                   str(ROOT / "tests/fixtures/native-render-state.cpp"),
                                   "-o", str(cls.binary), *flags.stdout.split()],
                                  capture_output=True, text=True, timeout=60)
        if compiled.returncode:
            raise AssertionError(compiled.stderr)

    def run_case(self, case):
        result = subprocess.run([str(self.binary), case], capture_output=True, text=True,
                                env=dict(os.environ, EGL_PLATFORM="surfaceless", LIBGL_ALWAYS_SOFTWARE="1"),
                                timeout=15)
        if result.returncode == 77:
            self.skipTest("Surfaceless EGL unavailable")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("RENDER_STATE_OK", result.stdout)

    def test_material_texture_units_stay_coherent_with_the_compositor(self):
        self.run_case("textures")

    def test_retained_blur_copies_the_returned_result_not_the_bound_target(self):
        self.run_case("blur")

    def test_capture_restores_bindings_viewport_and_scissor_on_reuse_and_resize(self):
        self.run_case("capture")

    def test_scene_and_window_blur_prepare_the_lens_halo_before_rendering(self):
        self.run_case("damage")

    def test_sidebar_refreshes_a_backdrop_from_an_older_frame_or_output_size(self):
        self.run_case("frame")
