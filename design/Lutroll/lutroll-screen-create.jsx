// lutroll-screen-create.jsx — Create LUT flow (import → analyze → name)

const { useState: lrCrUseState, useEffect: lrCrUseEffect } = React;

function CreateScreen({ onCancel, onCreated, accent }) {
  // step: "import" | "analyze" | "name"
  const [step, setStep] = lrCrUseState("import");
  const [name, setName] = lrCrUseState("");
  const [paletteVisible, setPaletteVisible] = lrCrUseState(0);

  // analyze animation — reveals swatches one by one then advances
  lrCrUseEffect(() => {
    if (step !== "analyze") return;
    setPaletteVisible(0);
    const timers = LR_CREATE_PALETTE.map((_, i) =>
      setTimeout(() => setPaletteVisible(v => v + 1), 280 + i * 240)
    );
    const advance = setTimeout(() => setStep("name"), 280 + LR_CREATE_PALETTE.length * 240 + 700);
    return () => { timers.forEach(clearTimeout); clearTimeout(advance); };
  }, [step]);

  return (
    <div style={{ minHeight: "100%", display: "flex", flexDirection: "column", position: "relative", paddingTop: 54 }}>
      {/* header */}
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "8px 18px 16px",
      }}>
        <IconButton onClick={onCancel}><Icon.close/></IconButton>
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          {["import", "analyze", "name"].map((s, i) => {
            const idx = ["import", "analyze", "name"].indexOf(step);
            const active = i <= idx;
            return (
              <div key={s} style={{
                width: i === idx ? 22 : 6, height: 6, borderRadius: 999,
                background: active ? "var(--ink-900)" : "var(--ink-200)",
                transition: "all .3s ease",
              }}/>
            );
          })}
        </div>
        <div style={{ width: 44 }}/>
      </div>

      <div style={{ padding: "0 22px", flex: 1, display: "flex", flexDirection: "column" }}>
        {step === "import" && <ImportStep onPick={() => setStep("analyze")} accent={accent}/>}
        {step === "analyze" && <AnalyzeStep visibleCount={paletteVisible} accent={accent}/>}
        {step === "name" && (
          <NameStep
            name={name} setName={setName}
            onCreate={() => onCreated({ name: name || "Untitled Roll" })}
            onBack={() => setStep("import")}
            accent={accent}
          />
        )}
      </div>
    </div>
  );
}

/* ── Step 1: Import ────────────────────────────────────── */
function ImportStep({ onPick, accent }) {
  return (
    <div className="lr-anim-up" style={{ flex: 1, display: "flex", flexDirection: "column" }}>
      <div style={{ marginBottom: 22 }}>
        <div className="lr-label" style={{ marginBottom: 8 }}>Step 1 of 3</div>
        <h1 className="lr-display" style={{ fontSize: 38, lineHeight: 1.04, margin: 0, marginBottom: 10 }}>
          Pick a photo whose <em>color</em> you love.
        </h1>
        <p style={{ fontSize: 14, color: "var(--ink-500)", margin: 0, lineHeight: 1.45 }}>
          We'll read its tones and build a reusable LUT — like making your own film stock.
        </p>
      </div>

      {/* drop zone */}
      <button onClick={onPick} style={{
        flex: 1, minHeight: 280, marginBottom: 16,
        background: "var(--cream-50)",
        border: "1.5px dashed var(--ink-300)",
        borderRadius: 26, padding: 24,
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        gap: 16, position: "relative", overflow: "hidden", textAlign: "center",
      }}>
        {/* ghost film frame */}
        <div style={{
          width: 130, height: 90, borderRadius: 10, background: "#2A2520",
          padding: "8px 6px", position: "relative",
          boxShadow: "0 12px 30px -10px rgba(31,26,20,0.3)",
        }}>
          <div style={{
            position: "absolute", top: 2, left: 6, right: 6, height: 4,
            backgroundImage: "radial-gradient(circle, #0f0c09 0 1.5px, transparent 2px)",
            backgroundSize: "10px 4px", backgroundRepeat: "repeat-x",
          }}/>
          <div style={{
            position: "absolute", bottom: 2, left: 6, right: 6, height: 4,
            backgroundImage: "radial-gradient(circle, #0f0c09 0 1.5px, transparent 2px)",
            backgroundSize: "10px 4px", backgroundRepeat: "repeat-x",
          }}/>
          <div style={{
            height: "100%", borderRadius: 4,
            background: `linear-gradient(135deg, ${accent || "var(--peach)"}, var(--butter), var(--sage))`,
            opacity: 0.85,
          }}/>
        </div>
        <div>
          <div className="lr-display" style={{ fontSize: 22, color: "var(--ink-900)" }}>
            Tap to pick a reference
          </div>
          <div style={{ fontSize: 13, color: "var(--ink-500)", marginTop: 4 }}>
            JPG, PNG, HEIC — any photo you have.
          </div>
        </div>
      </button>

      <div style={{ display: "flex", gap: 8 }}>
        <PillButton variant="cream" size="md" full leading={<Icon.photo s={18}/>} onClick={onPick} style={{ whiteSpace: "nowrap" }}>
          From Photos
        </PillButton>
        <PillButton variant="cream" size="md" full leading={<Icon.upload s={18}/>} onClick={onPick} style={{ whiteSpace: "nowrap" }}>
          From Files
        </PillButton>
      </div>
    </div>
  );
}

/* ── Step 2: Analyze ────────────────────────────────────── */
function AnalyzeStep({ visibleCount, accent }) {
  return (
    <div className="lr-anim-fade" style={{ flex: 1, display: "flex", flexDirection: "column" }}>
      <div style={{ marginBottom: 18 }}>
        <div className="lr-label" style={{ marginBottom: 8 }}>Step 2 of 3</div>
        <h1 className="lr-display" style={{ fontSize: 36, lineHeight: 1.05, margin: 0, marginBottom: 8 }}>
          Reading the <em>colors</em>…
        </h1>
        <p style={{ fontSize: 14, color: "var(--ink-500)", margin: 0 }}>
          This usually takes a few seconds.
        </p>
      </div>

      {/* photo with floating swatches */}
      <div style={{
        position: "relative", borderRadius: 22, overflow: "hidden",
        marginBottom: 22, boxShadow: "var(--shadow-pop)",
        aspectRatio: "3 / 4", maxHeight: 360,
      }}>
        <img src={LR_CREATE_SAMPLE} alt="" style={{
          width: "100%", height: "100%", objectFit: "cover", display: "block",
        }}/>

        {/* scanning line */}
        <div style={{
          position: "absolute", left: 0, right: 0, height: 2,
          top: "50%",
          background: `linear-gradient(90deg, transparent, ${accent || "#fff"}, transparent)`,
          boxShadow: `0 0 20px ${accent || "#fff"}`,
          animation: "lr-scan 2.2s ease-in-out infinite",
        }}/>
        <style>{`
          @keyframes lr-scan {
            0%   { top: 10%; opacity: 0; }
            12%  { opacity: 1; }
            88%  { opacity: 1; }
            100% { top: 90%; opacity: 0; }
          }
        `}</style>

        {/* floating swatch pills */}
        <div style={{
          position: "absolute", bottom: 14, left: 14, right: 14,
          display: "flex", gap: 8, flexWrap: "wrap",
        }}>
          {LR_CREATE_PALETTE.map((c, i) => (
            i < visibleCount ? (
              <div key={i} className="lr-mono" style={{
                display: "inline-flex", alignItems: "center", gap: 6,
                padding: "6px 10px 6px 6px", borderRadius: 999,
                background: "rgba(255,255,255,0.92)",
                color: "var(--ink-900)", fontSize: 10.5, letterSpacing: 0,
                boxShadow: "0 6px 16px -6px rgba(0,0,0,0.4)",
                animation: "lr-pop-swatch 380ms cubic-bezier(.2,.8,.2,1) both",
              }}>
                <span style={{
                  width: 16, height: 16, borderRadius: 999, background: c,
                  boxShadow: "inset 0 0 0 1px rgba(0,0,0,0.1)",
                }}/>
                {c.toUpperCase()}
              </div>
            ) : null
          ))}
        </div>
      </div>

      {/* progress text */}
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "center", gap: 10,
        color: "var(--ink-500)", fontSize: 13.5, whiteSpace: "nowrap",
      }}>
        <span style={{ display: "inline-flex", gap: 4 }}>
          {[0, 1, 2].map(i => (
            <span key={i} style={{
              width: 6, height: 6, borderRadius: 999, background: "var(--ink-700)",
              animation: `lr-pulse-dot 1.4s ${i*0.18}s ease-in-out infinite`,
            }}/>
          ))}
        </span>
        Building <span className="lr-mono" style={{ fontSize: 12 }}>32×32×32</span> color cube
      </div>
    </div>
  );
}

/* ── Step 3: Name ────────────────────────────────────── */
function NameStep({ name, setName, onCreate, onBack, accent }) {
  const SUGGESTED = ["Roadtrip Sky", "Desert Light", "Mountain Drive", "Open Road"];
  return (
    <div className="lr-anim-up" style={{ flex: 1, display: "flex", flexDirection: "column" }}>
      <div style={{ marginBottom: 18 }}>
        <div className="lr-label" style={{ marginBottom: 8 }}>Step 3 of 3</div>
        <h1 className="lr-display" style={{ fontSize: 38, lineHeight: 1.04, margin: 0, marginBottom: 8 }}>
          Name your <em>roll</em>.
        </h1>
        <p style={{ fontSize: 14, color: "var(--ink-500)", margin: 0 }}>
          Something memorable — you'll see it in your library.
        </p>
      </div>

      {/* preview cartridge */}
      <div style={{
        background: "var(--cream-50)", border: "1px solid var(--hairline)",
        borderRadius: 22, padding: 14, marginBottom: 22, boxShadow: "var(--shadow-card)",
      }}>
        <div style={{
          height: 30, borderRadius: 8, background: "var(--ink-900)", color: "var(--cream-50)",
          display: "flex", alignItems: "center", padding: "0 12px", marginBottom: 12,
          justifyContent: "space-between",
        }}>
          <span className="lr-mono" style={{ fontSize: 9.5, letterSpacing: "0.18em", opacity: 0.6 }}>
            LUT · NEW
          </span>
          <span style={{ width: 12, height: 12, borderRadius: 999, background: accent || LR_CREATE_PALETTE[0] }}/>
        </div>
        <div style={{
          height: 120, borderRadius: 10, overflow: "hidden",
          background: "#0F0C09", padding: "6px 6px",
        }}>
          <div style={{
            height: "100%", borderRadius: 4, overflow: "hidden",
          }}>
            <img src={LR_CREATE_SAMPLE} alt="" style={{
              width: "100%", height: "100%", objectFit: "cover", display: "block",
              filter: "sepia(0.1) saturate(1.1) contrast(1.02)",
            }}/>
          </div>
        </div>
        <div style={{ marginTop: 12, display: "flex", justifyContent: "space-between", alignItems: "center", gap: 8 }}>
          <div className="lr-display" style={{ fontSize: 22, color: name ? "var(--ink-900)" : "var(--ink-300)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis", minWidth: 0, flex: 1 }}>
            {name || "Untitled Roll"}
          </div>
          <PaletteRow colors={LR_CREATE_PALETTE} size={12} gap={4}/>
        </div>
      </div>

      {/* input */}
      <div style={{
        position: "relative",
        background: "var(--cream-50)", border: "1px solid var(--hairline-strong)",
        borderRadius: 16, padding: "14px 16px", marginBottom: 12,
      }}>
        <div className="lr-label" style={{ fontSize: 10, marginBottom: 6 }}>Name</div>
        <input
          value={name}
          onChange={e => setName(e.target.value)}
          placeholder="e.g. Roadtrip Sky"
          autoFocus
          style={{
            width: "100%", border: 0, outline: 0, background: "transparent",
            fontSize: 18, fontFamily: "var(--font-display)", color: "var(--ink-900)",
            letterSpacing: "-0.01em",
          }}
        />
      </div>

      {/* suggestions */}
      <div style={{
        display: "flex", gap: 6, flexWrap: "wrap", marginBottom: 22,
      }}>
        {SUGGESTED.map(s => (
          <button key={s} onClick={() => setName(s)} style={{
            padding: "7px 12px", borderRadius: 999,
            background: "transparent", border: "1px solid var(--hairline-strong)",
            color: "var(--ink-700)", fontSize: 12.5, whiteSpace: "nowrap",
            display: "inline-flex", alignItems: "center", gap: 6,
          }}>
            <Icon.sparkle s={12} c="var(--ink-400)"/>
            {s}
          </button>
        ))}
      </div>

      <div style={{ flex: 1 }}/>

      <div style={{ display: "flex", gap: 10, paddingBottom: 32 }}>
        <PillButton variant="ghost" size="lg" onClick={onBack} style={{ whiteSpace: "nowrap" }}>Back</PillButton>
        <PillButton variant="ink" size="lg" full onClick={onCreate} style={{ whiteSpace: "nowrap" }}>
          Save as film roll
        </PillButton>
      </div>
    </div>
  );
}

Object.assign(window, { CreateScreen });
