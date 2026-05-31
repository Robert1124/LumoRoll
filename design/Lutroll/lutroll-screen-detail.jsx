// lutroll-screen-detail.jsx — Film Roll Detail (the heart of the app)

const { useState: lrDtUseState } = React;

function DetailScreen({ roll, onBack, onApply, onPhoto, onExport, accent, darkRoll }) {
  const [intensity, setIntensity] = lrDtUseState(100);

  const bg = darkRoll ? "var(--noir-900)" : "var(--cream-100)";
  const surface = darkRoll ? "var(--noir-800)" : "var(--cream-50)";
  const ink = darkRoll ? "var(--cream-50)" : "var(--ink-900)";
  const sub = darkRoll ? "rgba(255,255,255,0.55)" : "var(--ink-500)";
  const hairline = darkRoll ? "rgba(255,255,255,0.08)" : "var(--hairline)";

  return (
    <div style={{
      minHeight: "100%", background: bg, color: ink,
      paddingBottom: 40, paddingTop: 54, position: "relative",
    }}>
      {/* header — close on left, label center, more on right */}
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "8px 18px 14px",
      }}>
        <IconButton onClick={onBack}
          bg={darkRoll ? "rgba(255,255,255,0.08)" : "rgba(31,26,20,0.04)"}
          color={ink} border={hairline}>
          <Icon.back c={ink}/>
        </IconButton>
        <div className="lr-mono" style={{ fontSize: 10.5, letterSpacing: "0.18em", color: sub }}>
          FILM ROLL · {roll.id.toUpperCase().replace(/_/g, "·")}
        </div>
        <IconButton bg={darkRoll ? "rgba(255,255,255,0.08)" : "rgba(31,26,20,0.04)"}
          color={ink} border={hairline}>
          <Icon.more c={ink}/>
        </IconButton>
      </div>

      {/* title block */}
      <div style={{ padding: "0 22px 18px" }}>
        <h1 className="lr-display" style={{
          fontSize: 46, lineHeight: 1.02, margin: 0, color: ink, marginBottom: 12,
          letterSpacing: "-0.025em",
        }}>{roll.name}</h1>

        <div style={{
          display: "flex", alignItems: "center", gap: 10, color: sub, fontSize: 12.5,
          fontWeight: 500, flexWrap: "wrap",
        }}>
          <span style={{ whiteSpace: "nowrap" }}>Created {roll.createdAt}</span>
          <span style={{ width: 3, height: 3, borderRadius: 999, background: sub, opacity: 0.5 }}/>
          <span style={{ whiteSpace: "nowrap" }}>Used on {roll.photos.length} photos</span>
          <span style={{ width: 3, height: 3, borderRadius: 999, background: sub, opacity: 0.5 }}/>
          <PaletteRow colors={roll.palette} size={10} gap={3}/>
        </div>
      </div>

      {/* film strip — continuous, sample first */}
      <div style={{ padding: "0 14px 18px" }}>
        <FilmStrip height={220} dark={darkRoll}>
          {/* Sample frame */}
          <FilmFrame
            src={roll.sample}
            filter={roll.filter}
            width={170}
            badge="SAMPLE"
            onClick={() => onPhoto({ rollId: roll.id, photoIndex: -1, src: roll.sample, isSample: true })}
          />
          {roll.photos.map((src, i) => (
            <FilmFrame
              key={i}
              src={src}
              filter={roll.filter}
              width={170}
              label={`F·${String(i+1).padStart(2, "0")}`}
              onClick={() => onPhoto({ rollId: roll.id, photoIndex: i, src })}
            />
          ))}
          {/* "add photo" tile at end of strip */}
          <button onClick={onApply} style={{
            flex: "0 0 auto", width: 170, height: "100%", borderRadius: 4,
            background: "rgba(255,255,255,0.04)",
            border: "1.5px dashed rgba(255,255,255,0.18)",
            color: "rgba(255,255,255,0.6)",
            display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
            gap: 8, scrollSnapAlign: "center",
          }}>
            <Icon.plus s={26} c="rgba(255,255,255,0.7)"/>
            <span className="lr-mono" style={{ fontSize: 10, letterSpacing: "0.14em" }}>ADD PHOTO</span>
          </button>
        </FilmStrip>
        <div style={{ display: "flex", justifyContent: "center", marginTop: 10 }}>
          <div className="lr-mono" style={{ fontSize: 10, letterSpacing: "0.14em", color: sub, whiteSpace: "nowrap" }}>
            ◀ swipe ▶ &nbsp;·&nbsp; {roll.photos.length + 1} frames
          </div>
        </div>
      </div>

      {/* Action row — Import is primary, Export LUT secondary */}
      <div style={{
        margin: "10px 18px 18px", display: "flex", gap: 10,
      }}>
        <PillButton variant={darkRoll ? "cream" : "ink"} size="lg" full
          leading={<Icon.photo s={18} c={darkRoll ? "var(--ink-900)" : "var(--cream-50)"}/>}
          onClick={onApply}
          style={{ whiteSpace: "nowrap" }}
        >
          Import photo
        </PillButton>
        <PillButton variant="ghost" size="lg"
          leading={<Icon.cube s={16}/>}
          onClick={onExport}
          style={{
            background: darkRoll ? "rgba(255,255,255,0.06)" : undefined,
            color: ink, whiteSpace: "nowrap",
            border: `1px solid ${darkRoll ? "rgba(255,255,255,0.12)" : "var(--hairline-strong)"}`,
          }}
        >
          .cube
        </PillButton>
      </div>

      {/* Intensity card */}
      <div style={{
        margin: "0 18px 14px",
        background: surface, border: `1px solid ${hairline}`,
        borderRadius: 22, padding: 18,
        boxShadow: darkRoll ? "none" : "var(--shadow-card)",
      }}>
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          marginBottom: 14,
        }}>
          <div>
            <div className="lr-label" style={{ color: darkRoll ? "rgba(255,255,255,0.5)" : undefined, marginBottom: 4 }}>
              Intensity
            </div>
            <div className="lr-display" style={{ fontSize: 24, color: ink }}>
              {intensity}<span style={{ fontSize: 14, color: sub, marginLeft: 4 }}>%</span>
            </div>
          </div>
          {/* tiny before/after pair */}
          <div style={{ display: "flex", gap: 6 }}>
            <MiniThumb src={roll.sample}/>
            <MiniThumb src={roll.sample} filter={roll.filter} intensity={intensity}/>
          </div>
        </div>
        <Slider value={intensity} onChange={setIntensity} dark={darkRoll} accent={accent}/>
        <div style={{
          display: "flex", justifyContent: "space-between", marginTop: 8,
          fontSize: 10.5, color: sub, fontWeight: 500, letterSpacing: "0.04em",
        }}>
          <span>OFF</span><span>SUBTLE</span><span>FULL</span>
        </div>
      </div>

      {/* Note + meta */}
      <div style={{
        margin: "0 18px",
        background: "transparent", borderRadius: 18,
        padding: "4px 4px",
        color: sub, fontSize: 13, lineHeight: 1.45,
        display: "flex", alignItems: "flex-start", gap: 10,
      }}>
        <Icon.sparkle s={14} c={accent || "var(--peach)"}/>
        <span style={{ flex: 1 }}>
          <em className="lr-italic" style={{ color: ink, fontSize: 14 }}>
            "{roll.note}"
          </em>
        </span>
      </div>
    </div>
  );
}

/* Slider with cream track + ink thumb */
function Slider({ value, onChange, dark, accent }) {
  return (
    <div style={{ position: "relative", height: 24 }}>
      <input
        type="range" min="0" max="100" value={value}
        onChange={e => onChange(parseInt(e.target.value, 10))}
        style={{
          position: "absolute", inset: 0, width: "100%", opacity: 0,
          zIndex: 2, cursor: "pointer",
        }}
      />
      {/* track */}
      <div style={{
        position: "absolute", top: 10, left: 0, right: 0, height: 4, borderRadius: 999,
        background: dark ? "rgba(255,255,255,0.12)" : "var(--cream-200)",
      }}/>
      {/* fill */}
      <div style={{
        position: "absolute", top: 10, left: 0, width: `${value}%`, height: 4, borderRadius: 999,
        background: dark ? "var(--cream-50)" : "var(--ink-900)",
      }}/>
      {/* thumb */}
      <div style={{
        position: "absolute", top: 0, left: `calc(${value}% - 12px)`,
        width: 24, height: 24, borderRadius: 999,
        background: dark ? "var(--cream-50)" : "var(--ink-900)",
        boxShadow: "0 1px 0 rgba(255,255,255,0.15) inset, 0 6px 14px -4px rgba(0,0,0,0.35)",
        border: `2px solid ${dark ? "var(--noir-800)" : "var(--cream-50)"}`,
      }}/>
    </div>
  );
}

function MiniThumb({ src, filter, intensity = 100 }) {
  return (
    <div style={{
      width: 44, height: 44, borderRadius: 10, overflow: "hidden",
      background: "#0F0C09", position: "relative",
      boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.06)",
    }}>
      <img src={src} alt="" style={{
        width: "100%", height: "100%", objectFit: "cover", display: "block",
        filter: filter || undefined,
        opacity: filter ? intensity / 100 : 1,
      }}/>
      {filter && intensity < 100 && (
        <img src={src} alt="" style={{
          position: "absolute", inset: 0,
          width: "100%", height: "100%", objectFit: "cover", display: "block",
          opacity: 1 - intensity / 100, zIndex: -1,
        }}/>
      )}
    </div>
  );
}

Object.assign(window, { DetailScreen });
