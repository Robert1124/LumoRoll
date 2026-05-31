// lutroll-app.jsx — root app, routing, tweaks panel

const { useState: lrAppUseState, useEffect: lrAppUseEffect } = React;

/* tweak defaults — between markers so the host can persist edits */
const LR_TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "#E89B7A",
  "palette": "Cream",
  "grain": true,
  "darkRoll": false,
  "density": "Comfy"
}/*EDITMODE-END*/;

const LR_PALETTES = {
  Cream:  { bg: "#F4EFE6", surface: "#FBF7EF", ink: "#1F1A14", accent: "#E89B7A" },
  Bone:   { bg: "#EEEAE0", surface: "#F7F3E9", ink: "#1B1814", accent: "#C97B4E" },
  Mist:   { bg: "#E8E6E0", surface: "#F2F0EB", ink: "#1C1F22", accent: "#7A85A0" },
  Linen:  { bg: "#EFE9DC", surface: "#F8F2E4", ink: "#22180E", accent: "#A8B89A" },
};

const ACCENT_OPTIONS = [
  "#E89B7A", // peach
  "#C97B4E", // terracotta
  "#A8B89A", // sage
  "#7A85A0", // dusk
  "#E8C26A", // butter
  "#D9938E", // rose
];

function LutrollApp() {
  /* ── tweaks ───────────────────────────── */
  const [t, setTweak] = useTweaks(LR_TWEAK_DEFAULTS);
  const palette = LR_PALETTES[t.palette] || LR_PALETTES.Cream;
  const accent = t.accent || palette.accent;

  // apply palette CSS vars to root of app
  lrAppUseEffect(() => {
    const root = document.documentElement;
    root.style.setProperty("--cream-100", palette.bg);
    root.style.setProperty("--cream-50",  palette.surface);
    root.style.setProperty("--ink-900",   palette.ink);
    root.style.setProperty("--peach",     accent);
  }, [palette, accent]);

  /* ── router state ─────────────────────── */
  // route: { name: "library" | "create" | "detail" | "apply" | "fullscreen", params }
  const [history, setHistory] = lrAppUseState([{ name: "library" }]);
  const route = history[history.length - 1];
  const [rolls, setRolls] = lrAppUseState(LR_ROLLS);
  const [toast, setToast] = lrAppUseState({ visible: false, message: "" });
  const [transition, setTransition] = lrAppUseState(null); // for entry animation key

  // notify the frame chrome so it can swap status bar to light icons on dark screens
  lrAppUseEffect(() => {
    const isDark = route.name === "fullscreen" || (route.name === "detail" && t.darkRoll);
    window.dispatchEvent(new CustomEvent("lr-route", { detail: { name: route.name, dark: isDark } }));
  }, [route.name, t.darkRoll]);

  const push = (r) => { setTransition(Date.now()); setHistory(h => [...h, r]); };
  const pop  = ()  => setHistory(h => h.length > 1 ? h.slice(0, -1) : h);
  const reset = (r) => { setTransition(Date.now()); setHistory([r]); };

  const showToast = (message, ms = 2200) => {
    setToast({ visible: true, message });
    setTimeout(() => setToast(t => ({ ...t, visible: false })), ms);
  };

  const findRoll = (id) => rolls.find(r => r.id === id);

  /* ── action handlers ──────────────────── */
  const openRoll = (id) => push({ name: "detail", rollId: id });
  const startCreate = () => push({ name: "create" });
  const finishCreate = ({ name }) => {
    const newRoll = {
      id: `r_${Date.now()}`,
      name: name,
      createdAt: "Today",
      sample: LR_CREATE_SAMPLE,
      palette: LR_CREATE_PALETTE,
      filter: "sepia(0.18) saturate(1.12) hue-rotate(-6deg) contrast(1.02)",
      note: "Fresh roll — apply it to a photo to start the strip.",
      photos: [],
    };
    setRolls(r => [newRoll, ...r]);
    reset({ name: "library" });
    showToast(`"${name}" added to your library`);
  };
  const openApply = (rollId) => push({ name: "apply", rollId });
  const openPhoto = (params) => push({ name: "fullscreen", ...params });
  const savePhoto = (rollId, destination) => {
    if (destination === "roll") {
      setRolls(rs => rs.map(r => r.id === rollId
        ? { ...r, photos: [...r.photos, photo(`fresh-${rollId}-${r.photos.length}`)] }
        : r));
      pop();
      showToast(`Saved to ${findRoll(rollId).name}`);
    } else {
      showToast("Saved to Photos");
    }
  };

  const exportLut = (rollName) => showToast(`${rollName}.cube exported`);

  /* ── render screens ───────────────────── */
  const screen = (() => {
    if (route.name === "library") {
      return <LibraryScreen
        rolls={rolls}
        onOpenRoll={openRoll}
        onCreate={startCreate}
        accent={accent}
      />;
    }
    if (route.name === "create") {
      return <CreateScreen
        onCancel={pop}
        onCreated={finishCreate}
        accent={accent}
      />;
    }
    if (route.name === "detail") {
      const roll = findRoll(route.rollId);
      return <DetailScreen
        roll={roll}
        onBack={pop}
        onApply={() => openApply(roll.id)}
        onPhoto={(p) => openPhoto(p)}
        onExport={() => exportLut(roll.name)}
        accent={accent}
        darkRoll={t.darkRoll}
      />;
    }
    if (route.name === "apply") {
      const roll = findRoll(route.rollId);
      return <ApplyScreen
        roll={roll}
        onBack={pop}
        onSaved={({ destination }) => savePhoto(route.rollId, destination)}
        accent={accent}
      />;
    }
    if (route.name === "fullscreen") {
      const roll = findRoll(route.rollId);
      return <FullscreenScreen
        roll={roll}
        startIndex={route.photoIndex}
        onClose={pop}
        accent={accent}
      />;
    }
    return null;
  })();

  return (
    <div className={`lr-app ${t.grain ? "lr-grain" : ""}`}
      style={{ position: "relative", height: "100%", overflow: "hidden" }}>
      <div className="lr-paper" style={{ position: "absolute", inset: 0, zIndex: 0 }}/>
      <div key={transition || "init"} style={{
        position: "relative", zIndex: 1, height: "100%", overflowY: "auto",
      }}>
        {screen}
      </div>
      <Toast {...toast} accent={accent}/>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Color">
          <TweakSelect label="Palette" value={t.palette}
            options={["Cream", "Bone", "Mist", "Linen"]}
            onChange={(v) => setTweak("palette", v)}/>
          <TweakColor label="Accent" value={t.accent}
            options={ACCENT_OPTIONS}
            onChange={(v) => setTweak("accent", v)}/>
        </TweakSection>
        <TweakSection label="Style">
          <TweakToggle label="Film grain texture" value={t.grain}
            onChange={(v) => setTweak("grain", v)}/>
          <TweakToggle label="Dark roll detail" value={t.darkRoll}
            onChange={(v) => setTweak("darkRoll", v)}/>
        </TweakSection>
        <TweakSection label="Jump to">
          <TweakButton onClick={() => reset({ name: "library" })}>Library</TweakButton>
          <TweakButton onClick={() => reset({ name: "create" })}>Create a roll</TweakButton>
          <TweakButton onClick={() => reset({ name: "detail", rollId: "warm_picnic" })}>Warm Picnic detail</TweakButton>
          <TweakButton onClick={() => reset({ name: "detail", rollId: "tokyo_night" })}>Tokyo Night detail</TweakButton>
          <TweakButton onClick={() => reset({ name: "apply", rollId: "sunny_film" })}>Apply Sunny Film</TweakButton>
          <TweakButton onClick={() => reset({ name: "fullscreen", rollId: "tokyo_night", photoIndex: 0 })}>Fullscreen photo</TweakButton>
        </TweakSection>
      </TweaksPanel>
    </div>
  );
}

/* hook into useTweaks API from starter — provide a `.set` method shim */
// (no shims — useTweaks returns [values, setTweak] directly)
window.LutrollApp = LutrollApp;
