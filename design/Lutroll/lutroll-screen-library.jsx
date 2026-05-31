// lutroll-screen-library.jsx — Home / LUT Library

const { useState: lrLibUseState } = React;

function RollCard({ roll, onClick, accent }) {
  // a small card that visually reads as a film cartridge
  return (
    <button onClick={onClick} className="lr-anim-up" style={{
      display: "block", textAlign: "left", width: "100%",
      background: "var(--cream-50)", border: "1px solid var(--hairline)",
      borderRadius: 22, padding: 14, position: "relative",
      boxShadow: "var(--shadow-card)",
      transition: "transform .2s ease, box-shadow .2s ease"
    }}>
      {/* film cartridge top — tape strip with LUT name */}
      <div style={{
        height: 28, borderRadius: 8,
        background: "var(--ink-900)",
        color: "var(--cream-50)",
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "0 10px 0 12px", marginBottom: 12, position: "relative",
        boxShadow: "inset 0 -1px 0 rgba(255,255,255,0.06)"
      }}>
        <span className="lr-mono" style={{
          fontSize: 9, letterSpacing: "0.14em", opacity: 0.55,
          whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
          minWidth: 0
        }}>
          {roll.name.toUpperCase()}
        </span>
        <span style={{
          width: 12, height: 12, borderRadius: 999,
          background: accent || roll.palette[0],
          boxShadow: "inset 0 0 0 1.5px rgba(0,0,0,0.25)"
        }} />
      </div>

      {/* film body — sample image with sprocket frame */}
      <div style={{
        position: "relative", borderRadius: 12, overflow: "hidden",
        background: "#0F0C09", padding: "8px 6px"
      }}>
        <div style={{
          position: "absolute", top: 2, left: 8, right: 8, height: 5,
          backgroundImage: "radial-gradient(circle, #2a2520 0 1.6px, transparent 2px)",
          backgroundSize: "10px 5px", backgroundRepeat: "repeat-x"
        }} />
        <div style={{
          position: "absolute", bottom: 2, left: 8, right: 8, height: 5,
          backgroundImage: "radial-gradient(circle, #2a2520 0 1.6px, transparent 2px)",
          backgroundSize: "10px 5px", backgroundRepeat: "repeat-x"
        }} />
        <div style={{
          height: 140, borderRadius: 4, overflow: "hidden", position: "relative"
        }}>
          <img src={roll.sample} alt="" style={{
            width: "100%", height: "100%", objectFit: "cover",
            filter: roll.filter, display: "block"
          }} />
          {/* faint film grain corner */}
          <div style={{
            position: "absolute", inset: 0,
            background: "linear-gradient(135deg, rgba(255,255,255,0.06), transparent 40%)",
            pointerEvents: "none"
          }} />
        </div>
      </div>

      {/* metadata row */}
      <div style={{ marginTop: 10 }}>
        <div className="lr-display" style={{ fontSize: 22, lineHeight: 1.05, marginBottom: 6 }}>
          {roll.name}
        </div>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 6 }}>
          <div style={{
            display: "flex", alignItems: "center", gap: 6,
            fontSize: 11, color: "var(--ink-500)", fontWeight: 500,
            whiteSpace: "nowrap"
          }}>
            <span>{roll.photos.length} photos</span>
            <span style={{ width: 3, height: 3, borderRadius: 999, background: "var(--ink-300)", flex: "0 0 auto" }} />
            <span>{roll.createdAt}</span>
          </div>
          <PaletteRow colors={roll.palette.slice(0, 4)} size={9} gap={3} />
        </div>
      </div>
    </button>);

}

function LibraryScreen({ rolls, onOpenRoll, onCreate, accent }) {
  const [query, setQuery] = lrLibUseState("");
  const visible = rolls.filter((r) => r.name.toLowerCase().includes(query.toLowerCase()));

  return (
    <div style={{ minHeight: "100%", position: "relative", paddingBottom: 40 }}>
      {/* header — sticky so it stays anchored while the grid scrolls */}
      <div style={{
        position: "sticky", top: 0, zIndex: 5,
        padding: "62px 22px 18px",
        background: "color-mix(in oklab, var(--cream-100) 78%, transparent)",
        backdropFilter: "saturate(140%) blur(14px)",
        WebkitBackdropFilter: "saturate(140%) blur(14px)",
        borderBottom: "1px solid var(--hairline)"
      }}>
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between"
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            {/* tiny wordmark — film cartridge dot + name */}
            <div style={{
              width: 24, height: 24, borderRadius: 7, background: "var(--ink-900)",
              display: "flex", alignItems: "center", justifyContent: "center",
              position: "relative"
            }}>
              <div style={{
                width: 10, height: 10, borderRadius: "50%",
                background: accent || "var(--peach)"
              }} />
            </div>
            <span style={{ fontSize: 17, fontWeight: 600, letterSpacing: "-0.02em" }}>
              Lutroll
            </span>
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            <IconButton><Icon.search /></IconButton>
            <IconButton onClick={onCreate} bg="var(--ink-900)" color="var(--cream-50)" border="transparent">
              <Icon.plus c="var(--cream-50)" />
            </IconButton>
          </div>
        </div>
      </div>

      {/* roll grid */}
      <div style={{
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        gap: 12, padding: "20px 16px 0"
      }}>
        {visible.map((r, i) =>
        <div key={r.id} style={{ animationDelay: `${i * 40}ms` }}>
            <RollCard roll={r} onClick={() => onOpenRoll(r.id)} accent={accent} />
          </div>
        )}
      </div>

      {/* footer hint */}
      <div style={{
        marginTop: 18, padding: "0 22px",
        display: "flex", alignItems: "center", gap: 10,
        color: "var(--ink-400)", fontSize: 12.5
      }}>
        <span style={{ width: 6, height: 6, borderRadius: 999, background: accent || "var(--peach)" }} />
        Tip: long-press any roll to share or duplicate.
      </div>
    </div>);

}

function Chip({ children, active }) {
  return (
    <button style={{
      flex: "0 0 auto", height: 32, padding: "0 14px", borderRadius: 999,
      background: active ? "var(--ink-900)" : "var(--cream-50)",
      color: active ? "var(--cream-50)" : "var(--ink-700)",
      border: `1px solid ${active ? "transparent" : "var(--hairline)"}`,
      fontSize: 12.5, fontWeight: 500, letterSpacing: "-0.005em"
    }}>{children}</button>);

}

Object.assign(window, { LibraryScreen, RollCard });