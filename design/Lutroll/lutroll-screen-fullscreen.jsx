// lutroll-screen-fullscreen.jsx — fullscreen photo viewer with swipe nav

const { useState: lrFsUseState, useEffect: lrFsUseEffect, useRef: lrFsUseRef } = React;

function FullscreenScreen({ roll, startIndex = 0, onClose, accent }) {
  // photos: sample first, then user photos
  const photos = [
    { src: roll.sample, isSample: true, label: "Sample reference" },
    ...roll.photos.map((src, i) => ({ src, label: `Frame ${String(i+1).padStart(2, "0")}` })),
  ];
  // startIndex of -1 means sample (index 0 in `photos`)
  const initial = startIndex < 0 ? 0 : startIndex + 1;
  const [idx, setIdx] = lrFsUseState(initial);
  const [dragX, setDragX] = lrFsUseState(0);
  const startRef = lrFsUseRef(null);

  const current = photos[idx];

  const onPointerDown = (e) => {
    startRef.current = { x: e.clientX, t: Date.now() };
    e.currentTarget.setPointerCapture(e.pointerId);
  };
  const onPointerMove = (e) => {
    if (!startRef.current) return;
    setDragX(e.clientX - startRef.current.x);
  };
  const onPointerUp = (e) => {
    if (!startRef.current) return;
    const dx = e.clientX - startRef.current.x;
    if (dx < -60 && idx < photos.length - 1) setIdx(i => i + 1);
    else if (dx > 60 && idx > 0) setIdx(i => i - 1);
    startRef.current = null;
    setDragX(0);
  };

  return (
    <div style={{
      position: "absolute", inset: 0,
      background: "var(--noir-900)", color: "var(--cream-50)",
      display: "flex", flexDirection: "column", zIndex: 80,
      paddingTop: 54,
      animation: "lr-fade-in 240ms ease both",
    }}>
      {/* paper texture overlay for warmth */}
      <div style={{
        position: "absolute", inset: 0,
        background: "radial-gradient(circle at 50% 30%, rgba(232,155,122,0.06), transparent 60%)",
        pointerEvents: "none",
      }}/>

      {/* top bar */}
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "space-between",
        padding: "8px 16px 12px", position: "relative", zIndex: 10, gap: 12,
      }}>
        <IconButton onClick={onClose}
          bg="rgba(255,255,255,0.08)" color="var(--cream-50)" border="rgba(255,255,255,0.1)">
          <Icon.close c="var(--cream-50)"/>
        </IconButton>
        <div style={{ textAlign: "center", flex: 1, minWidth: 0 }}>
          <div className="lr-mono" style={{ fontSize: 9.5, letterSpacing: "0.16em", opacity: 0.5, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {roll.name.toUpperCase()}
          </div>
          <div style={{ fontSize: 13.5, fontWeight: 500, letterSpacing: "-0.005em", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            {current.label}
          </div>
        </div>
        <IconButton bg="rgba(255,255,255,0.08)" color="var(--cream-50)" border="rgba(255,255,255,0.1)">
          <Icon.more c="var(--cream-50)"/>
        </IconButton>
      </div>

      {/* main photo */}
      <div
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerUp}
        style={{
          flex: 1, position: "relative", overflow: "hidden",
          display: "flex", alignItems: "center", justifyContent: "center",
          touchAction: "pan-y",
        }}
      >
        <div style={{
          width: "100%", height: "100%", display: "flex",
          transform: `translateX(calc(${-idx * 100}% + ${dragX}px))`,
          transition: startRef.current ? "none" : "transform .4s cubic-bezier(.2,.8,.2,1)",
        }}>
          {photos.map((p, i) => (
            <div key={i} style={{
              flex: "0 0 100%", display: "flex", alignItems: "center", justifyContent: "center",
              padding: "0 16px",
            }}>
              <div style={{
                position: "relative", maxWidth: "100%", maxHeight: "100%",
                borderRadius: 12, overflow: "hidden",
                boxShadow: "0 30px 60px -20px rgba(0,0,0,0.6)",
              }}>
                <img src={p.src} alt="" style={{
                  display: "block", maxWidth: "100%", maxHeight: "55vh",
                  objectFit: "contain",
                  filter: roll.filter,
                }}/>
                {p.isSample && (
                  <div className="lr-mono" style={{
                    position: "absolute", top: 10, left: 10,
                    padding: "4px 9px", borderRadius: 6,
                    background: "var(--cream-50)", color: "var(--ink-900)",
                    fontSize: 9.5, letterSpacing: "0.14em",
                  }}>SAMPLE</div>
                )}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* dots */}
      <div style={{
        display: "flex", justifyContent: "center", gap: 5,
        padding: "8px 0", position: "relative", zIndex: 10,
      }}>
        {photos.map((_, i) => (
          <button key={i} onClick={() => setIdx(i)} style={{
            width: i === idx ? 18 : 5, height: 5, borderRadius: 999,
            background: i === idx ? "var(--cream-50)" : "rgba(255,255,255,0.25)",
            transition: "all .25s ease",
          }}/>
        ))}
      </div>

      {/* bottom action bar */}
      <div style={{
        padding: "10px 16px 16px", display: "flex", gap: 8, position: "relative", zIndex: 10,
      }}>
        <FsAction icon={<Icon.download s={20}/>} label="Save"/>
        <FsAction icon={<Icon.share s={20}/>}    label="Share"/>
        <FsAction icon={<Icon.sparkle s={18}/>}  label="Edit"/>
        <FsAction icon={<Icon.more s={20}/>}     label="More"/>
      </div>
    </div>
  );
}

function FsAction({ icon, label }) {
  return (
    <button style={{
      flex: 1, height: 54, borderRadius: 18,
      background: "rgba(255,255,255,0.06)",
      border: "1px solid rgba(255,255,255,0.08)",
      color: "var(--cream-50)",
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 2,
    }}>
      {icon}
      <span style={{ fontSize: 10.5, opacity: 0.75, letterSpacing: "-0.005em" }}>{label}</span>
    </button>
  );
}

Object.assign(window, { FullscreenScreen });
