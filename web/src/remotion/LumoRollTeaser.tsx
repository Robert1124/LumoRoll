import type {CSSProperties} from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';

const palette = ['#E89B7A', '#E8C26A', '#A8B89A', '#7A85A0'];

export const LumoRollTeaser = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const intro = spring({frame, fps, config: {damping: 18, stiffness: 110}});
  const filmX = interpolate(frame, [0, 180], [0, -180], {extrapolateRight: 'clamp'});
  const cardY = interpolate(intro, [0, 1], [80, 0]);
  const fade = interpolate(frame, [0, 18], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  return (
    <AbsoluteFill
      style={{
        background: '#F4EFE6',
        color: '#1F1A14',
        fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif',
        overflow: 'hidden',
      }}
    >
      <div style={grainStyle} />
      <div style={{position: 'absolute', inset: 76, display: 'grid', gridTemplateRows: 'auto 1fr auto'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 18, opacity: fade}}>
          <Img src={staticFile('lumoroll-assets/lumoroll-brand-icon.png')} style={{width: 72, height: 72, borderRadius: 18}} />
          <div style={{fontSize: 34, fontWeight: 760}}>LumoRoll</div>
        </div>

        <div style={{position: 'relative'}}>
          <div style={{...cardWrap, transform: `translate(-50%, calc(-50% + ${cardY}px)) rotate(-2deg)`}}>
            <SlideCard />
          </div>

          <div style={lightBoxWrap}>
            <Img src={staticFile('lumoroll-assets/lightbox-back-frame.png')} style={backFrameStyle} />
            <div style={{...filmStyle, transform: `translateX(${filmX}px)`}}>
              <div style={sprocketStyle} />
              <div style={filmFramesStyle}>
                {Array.from({length: 7}).map((_, index) => (
                  <div
                    // eslint-disable-next-line react/no-array-index-key
                    key={index}
                    style={{
                      ...filmCellStyle,
                      background: `linear-gradient(140deg, ${palette[index % palette.length]}, #F4EFE6 48%, #2A2520)`,
                      opacity: index === 2 ? 1 : 0.62,
                    }}
                  />
                ))}
              </div>
              <div style={sprocketStyle} />
            </div>
            <Img src={staticFile('lumoroll-assets/lightbox-front-block.png')} style={frontBlockStyle} />
          </div>
        </div>

        <div style={{maxWidth: 720, opacity: fade}}>
          <div style={monoStyle}>LOCAL COLOR ROLLS / 33x33x33 .CUBE</div>
          <div style={{fontFamily: 'Georgia, "Times New Roman", serif', fontSize: 92, lineHeight: 0.92, letterSpacing: 0}}>
            Create a personal Film Roll from one photo.
          </div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

const grainStyle: CSSProperties = {
  position: 'absolute',
  inset: 0,
  opacity: 0.38,
  backgroundImage: 'repeating-linear-gradient(0deg, rgba(31, 26, 20, 0.03) 0 1px, transparent 1px 5px)',
};

const monoStyle: CSSProperties = {
  marginBottom: 20,
  fontFamily: 'ui-monospace, "SF Mono", Menlo, Consolas, monospace',
  fontSize: 18,
  fontWeight: 780,
  letterSpacing: '0.14em',
  color: '#918879',
};

const cardWrap: CSSProperties = {
  position: 'absolute',
  left: '33%',
  top: '44%',
  width: 360,
  height: 360,
  filter: 'drop-shadow(0 28px 38px rgba(31, 26, 20, 0.22))',
};

const slideCardStyle: CSSProperties = {
  width: '100%',
  height: '100%',
  borderRadius: 20,
  padding: 34,
  background: 'linear-gradient(135deg, #FBF7EF, #EFE3CB 48%, #FBF7EF)',
  border: '1px solid rgba(31, 26, 20, 0.14)',
};

const lightBoxWrap: CSSProperties = {
  position: 'absolute',
  right: 10,
  top: 170,
  width: 440,
  height: 350,
  display: 'grid',
  placeItems: 'center',
};

const backFrameStyle: CSSProperties = {
  position: 'absolute',
  width: 250,
  height: 250,
  zIndex: 1,
};

const frontBlockStyle: CSSProperties = {
  position: 'absolute',
  width: 188,
  height: 188,
  zIndex: 3,
};

const filmStyle: CSSProperties = {
  position: 'absolute',
  zIndex: 2,
  width: 520,
  height: 122,
  display: 'grid',
  alignContent: 'center',
  gap: 6,
  background: '#0F0C09',
  borderRadius: 8,
  overflow: 'hidden',
};

const sprocketStyle: CSSProperties = {
  height: 8,
  backgroundImage: 'repeating-linear-gradient(90deg, rgba(255, 255, 255, 0.36) 0 4px, transparent 4px 11px)',
};

const filmFramesStyle: CSSProperties = {
  display: 'flex',
  gap: 12,
  height: 84,
  alignItems: 'center',
  paddingLeft: 90,
};

const filmCellStyle: CSSProperties = {
  flex: '0 0 118px',
  height: 84,
  borderRadius: 5,
  border: '1px solid rgba(255, 255, 255, 0.16)',
};

function SlideCard() {
  return (
    <div style={slideCardStyle}>
      <div style={{display: 'grid', gridTemplateColumns: '54px 1fr 14px', alignItems: 'center', gap: 12, color: '#A33A2E'}}>
        <span style={smallMono}>001</span>
        <strong style={{fontFamily: 'Georgia, "Times New Roman", serif', fontSize: 18, letterSpacing: '0.08em', textAlign: 'center'}}>
          WARM HAZE
        </strong>
        <i style={{width: 11, height: 11, borderRadius: '50%', background: '#A33A2E'}} />
      </div>
      <div style={{...smallMono, color: '#A33A2E', textAlign: 'center', marginTop: 8}}>COLOR ROLL</div>
      <div style={{width: 210, height: 126, margin: '36px auto 30px', padding: 6, borderRadius: 12, background: 'rgba(0,0,0,0.84)'}}>
        <div style={{height: '100%', borderRadius: 8, border: '2px solid rgba(0,0,0,0.46)', background: 'linear-gradient(140deg, #E89B7A, #E8C26A 46%, #7A85A0)'}} />
      </div>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'end', color: '#A33A2E'}}>
        <span style={smallMono}>LUT</span>
        <div style={{display: 'grid', justifyItems: 'end', gap: 8}}>
          <span style={{display: 'flex', gap: 5}}>
            {palette.map((color) => <i key={color} style={{width: 10, height: 10, borderRadius: '50%', background: color}} />)}
          </span>
          <span style={smallMono}>33x33x33</span>
        </div>
      </div>
    </div>
  );
}

const smallMono: CSSProperties = {
  fontFamily: 'ui-monospace, "SF Mono", Menlo, Consolas, monospace',
  fontSize: 13,
  fontWeight: 780,
  letterSpacing: '0.12em',
};
