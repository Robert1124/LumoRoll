// lutroll-screen-apply.jsx — Import & apply LUT to a new photo

const { useState: lrApUseState, useRef: lrApUseRef } = React;

/* candidate photos the user "just picked from their library" */
const LR_APPLY_CANDIDATES = [
  photo("apply-window-light-coffee", 900, 1200),
  photo("apply-cyclist-empty-street", 900, 1200),
  photo("apply-cake-on-plate", 900, 1200),
  photo("apply-woman-window-laptop", 900, 1200),
];

function ApplyScreen({ roll, onBack, onSaved, accent }) {
  const [picked, setPicked] = lrApUseState(LR_APPLY_CANDIDATES[0]);
  const [intensity, setIntensity] = lrApUseState(85);
  const [splitPos, setSplitPos] = lrApUseState(50); // before/after slider position
  const [mode, setMode] = lrApUseState("split"); // "split" | "after" | "before"
  const containerRef = lrApUseRef(null);

  const handleDrag = (e) => {
    const rect = containerRef.current.getBoundingClientRect();
    const x = (e.touches?.[0]?.clientX ?? e.clientX) - rect.left;
    const pct = Math.max(0, Math.min(100, (x / rect.width) * 100));
    setSplitPos(pct);
  };

  const filterStr = roll.filter;

  return (
    <div style={{
      minHeight: "100%", display: "flex", flexDirection: "column", position: "relative", paddingTop: 54,
      background: "var(--cream-100)",
    }}>
      {/* header */}
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "8px 18px 12px", gap: 12,
      }}>
        <IconButton onClick={onBack}><Icon.back/></IconButton>
        <div style={{ textAlign: "center", minWidth: 0, flex: 1 }}>
          <div className="lr-mono" style={{ fontSize: 9.5, letterSpacing: "0.18em", color: "var(--ink-400)" }}>
            APPLYING
          </div>
          <div style={{ fontSize: 14, fontWeight: 600, letterSpacing: "-0.01em", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {roll.name}
          </div>
        </div>
        <IconButton><Icon.more/></IconButton>
      </div>

      {/* mode segmented */}
      <div style={{ padding: "0 18px 14px", display: "flex", justifyContent: "center" }}>
        <div style={{
          display: "inline-flex", padding: 3, background: "var(--cream-200)",
          borderRadius: 999,
        }}>
          {[
            { id: "before", label: "Before" },
            { id: "split",  label: "Split" },
            { id: "after",  label: "After" },
          ].map(o => (
            <button key={o.id} onClick={() => setMode(o.id)} style={{
              height: 32, padding: "0 16px", borderRadius: 999,
              fontSize: 12.5, fontWeight: 500, letterSpacing: "-0.005em",
              background: mode === o.id ? "var(--cream-50)" : "transparent",
              color: mode === o.id ? "var(--ink-900)" : "var(--ink-500)",
              boxShadow: mode === o.id ? "0 1px 2px rgba(0,0,0,0.06), 0 4px 12px -6px rgba(0,0,0,0.12)" : "none",
              transition: "all .15s ease",
            }}>{o.label}</button>
          ))}
        </div>
      </div>

      {/* the photo preview */}
      <div style={{ padding: "0 16px", marginBottom: 14 }}>
        <div
          ref={containerRef}
          onPointerDown={(e) => mode === "split" && (e.currentTarget.setPointerCapture(e.pointerId), handleDrag(e))}
          onPointerMove={(e) => mode === "split" && e.buttons && handleDrag(e)}
          style={{
            position: "relative", borderRadius: 22, overflow: "hidden",
            aspectRatio: "3 / 4", maxHeight: 380,
            background: "#0F0C09", boxShadow: "var(--shadow-pop)",
            touchAction: "pan-y", userSelect: "none",
            cursor: mode === "split" ? "ew-resize" : "default",
          }}
        >
          {/* base (BEFORE) */}
          <img src={picked} alt="" style={{
            position: "absolute", inset: 0,
            width: "100%", height: "100%", objectFit: "cover",
          }}/>
          {/* AFTER overlay */}
          <div style={{
            position: "absolute", inset: 0,
            clipPath: mode === "split"
              ? `inset(0 0 0 ${splitPos}%)`
              : mode === "after" ? "inset(0)" : "inset(0 100% 0 0)",
            transition: mode === "split" ? "none" : "clip-path .35s ease",
          }}>
            <img src={picked} alt="" style={{
              width: "100%", height: "100%", objectFit: "cover", display: "block",
              filter: filterStr,
              opacity: intensity / 100,
            }}/>
            {/* base image behind to support intensity blend */}
            <img src={picked} alt="" style={{
              position: "absolute", inset: 0,
              width: "100%", height: "100%", objectFit: "cover", zIndex: -1,
              opacity: 1 - intensity / 100,
            }}/>
          </div>

          {/* split handle */}
          {mode === "split" && (
            <div style={{
              position: "absolute", top: 0, bottom: 0,
              left: `${splitPos}%`, width: 2, background: "rgba(255,255,255,0.9)",
              boxShadow: "0 0 0 1px rgba(0,0,0,0.2), 0 0 20px rgba(0,0,0,0.3)",
              transform: "translateX(-1px)",
            }}>
              <div style={{
                position: "absolute", top: "50%", left: "50%",
                transform: "translate(-50%, -50%)",
                width: 36, height: 36, borderRadius: 999,
                background: "var(--cream-50)",
                border: "1px solid var(--hairline-strong)",
                display: "flex", alignItems: "center", justifyContent: "center",
                boxShadow: "0 4px 16px rgba(0,0,0,0.3)",
              }}>
                <Icon.swap s={16}/>
              </div>
            </div>
          )}

          {/* labels */}
          <div style={{
            position: "absolute", top: 12, left: 12,
            display: mode === "after" ? "none" : "flex", gap: 6,
          }}>
            <Tag>Before</Tag>
          </div>
          <div style={{
            position: "absolute", top: 12, right: 12,
            display: mode === "before" ? "none" : "flex", gap: 6,
          }}>
            <Tag dark>{roll.name}</Tag>
          </div>
        </div>
      </div>

      {/* candidate strip — small thumbs of other photos in library */}
      <div style={{ padding: "0 16px 14px" }}>
        <div className="lr-label" style={{ marginBottom: 8, paddingLeft: 4 }}>From your library</div>
        <div className="lr-no-scrollbar" style={{
          display: "flex", gap: 8, overflowX: "auto", paddingBottom: 4,
        }}>
          {LR_APPLY_CANDIDATES.map(src => (
            <button key={src} onClick={() => setPicked(src)} style={{
              flex: "0 0 auto", width: 62, height: 84, borderRadius: 10,
              overflow: "hidden", position: "relative",
              border: `2px solid ${picked === src ? "var(--ink-900)" : "transparent"}`,
              padding: 0, background: "var(--cream-200)",
            }}>
              <img src={src} alt="" style={{
                width: "100%", height: "100%", objectFit: "cover", display: "block",
                filter: picked === src ? filterStr : undefined,
              }}/>
            </button>
          ))}
          <button style={{
            flex: "0 0 auto", width: 62, height: 84, borderRadius: 10,
            background: "var(--cream-50)", border: "1px dashed var(--ink-300)",
            color: "var(--ink-400)", display: "flex", alignItems: "center", justifyContent: "center",
          }}><Icon.plus s={18} c="var(--ink-400)"/></button>
        </div>
      </div>

      {/* intensity */}
      <div style={{
        margin: "0 18px 14px",
        background: "var(--cream-50)", border: "1px solid var(--hairline)",
        borderRadius: 22, padding: 16, boxShadow: "var(--shadow-card)",
      }}>
        <div style={{
          display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10,
        }}>
          <div className="lr-label">Intensity</div>
          <div className="lr-mono" style={{ fontSize: 12, color: "var(--ink-900)", fontWeight: 500 }}>
            {intensity}%
          </div>
        </div>
        <Slider value={intensity} onChange={setIntensity} accent={accent}/>
      </div>

      {/* primary action */}
      <div style={{
        padding: "0 18px 14px", display: "flex", gap: 10,
      }}>
        <PillButton variant="ghost" size="lg"
          leading={<Icon.download s={18}/>}
          onClick={() => onSaved({ destination: "photos" })}
        >
          Photos
        </PillButton>
        <PillButton variant="ink" size="lg" full
          leading={<Icon.film s={18} c="var(--cream-50)"/>}
          onClick={() => onSaved({ destination: "roll" })}
        >
          Save to {roll.name}
        </PillButton>
      </div>

      <div style={{
        textAlign: "center", fontSize: 11.5, color: "var(--ink-400)",
        padding: "0 18px 32px",
      }}>
        Drag the handle to compare
      </div>
    </div>
  );
}

function Tag({ children, dark }) {
  return (
    <div style={{
      padding: "5px 10px", borderRadius: 999,
      background: dark ? "rgba(255,255,255,0.92)" : "rgba(31,26,20,0.7)",
      backdropFilter: "blur(6px)",
      color: dark ? "var(--ink-900)" : "var(--cream-50)",
      fontSize: 11, fontWeight: 500, letterSpacing: "-0.005em",
      whiteSpace: "nowrap",
    }}>{children}</div>
  );
}

Object.assign(window, { ApplyScreen, LR_APPLY_CANDIDATES });
