import {useEffect, useMemo, useRef, useState} from 'react';
import gsap from 'gsap';

const assets = {
  brand: '/lumoroll-assets/lumoroll-brand-icon.png',
  backFrame: '/lumoroll-assets/lightbox-back-frame.png',
  frontBlock: '/lumoroll-assets/lightbox-front-block.png',
  backFrameDark: '/lumoroll-assets/lightbox-back-frame-dark.png',
  frontBlockDark: '/lumoroll-assets/lightbox-front-block-dark.png',
};

const TESTFLIGHT_URL = 'https://testflight.apple.com/join/bcH5zNCR';

const rolls = [
  {
    name: 'Warm Haze',
    serial: 1,
    count: 18,
    date: 'May 30',
    colors: ['#E89B7A', '#E8C26A', '#A8B89A', '#7A85A0'],
    photo: ['#f0a46f', '#b4c7b2', '#435f74'],
  },
  {
    name: 'Noon Portra',
    serial: 2,
    count: 9,
    date: 'May 26',
    colors: ['#D9938E', '#E8C26A', '#B6CDB6', '#8A7088'],
    photo: ['#d6a071', '#ece1bf', '#6f8d9d'],
  },
  {
    name: 'Night Roll',
    serial: 3,
    count: 14,
    date: 'May 24',
    colors: ['#7A85A0', '#8A7088', '#E89B7A', '#2A2520'],
    photo: ['#1a1612', '#4f5f85', '#d28b75'],
  },
];

const detailFrames = [
  ['#e99a72', '#f1d188', '#4b6f72'],
  ['#25221f', '#d99078', '#f3d697'],
  ['#9fb79a', '#f4efe6', '#7181a0'],
  ['#1a1612', '#6b5364', '#e89b7a'],
];

function App() {
  const [selectedRoll, setSelectedRoll] = useState(0);
  const [previewMode, setPreviewMode] = useState<'before' | 'split' | 'after'>('split');
  const [intensity, setIntensity] = useState(72);
  const [splitPosition, setSplitPosition] = useState(52);
  const rootRef = useRef<HTMLDivElement>(null);
  const heroStageRef = useRef<HTMLDivElement>(null);
  const splitRef = useRef<HTMLDivElement>(null);
  const splitPhotoRef = useRef<HTMLDivElement>(null);
  const splitDragPointerRef = useRef<number | null>(null);
  const intensityTrackRef = useRef<HTMLDivElement>(null);
  const intensityDragPointerRef = useRef<number | null>(null);

  useEffect(() => {
    const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    const context = gsap.context(() => {
      if (reducedMotion) {
        gsap.set(['.hero-copy', '.hero-card', '.lightbox-assembly', '.section-copy'], {autoAlpha: 1});
        return;
      }

      const timeline = gsap.timeline({defaults: {ease: 'power3.out'}});
      timeline
        .from('.site-nav', {y: -16, autoAlpha: 0, duration: 0.5})
        .from('.hero-copy > *', {y: 28, autoAlpha: 0, duration: 0.7, stagger: 0.08}, '<0.1')
        .from('.hero-card', {y: 52, rotationX: 10, autoAlpha: 0, duration: 0.8, stagger: {amount: 0.22, from: 'center'}}, '<0.1')
        .from('.hero-peek', {y: 34, autoAlpha: 0, duration: 0.55}, '<0.3');

      gsap.to('.film-track.motion', {
        x: -148,
        duration: 16,
        ease: 'none',
        repeat: 20,
        yoyo: true,
      });

      const cards = gsap.utils.toArray<HTMLElement>('.hero-card .slide-card');
      const xTo = cards.map((card) => gsap.quickTo(card, 'x', {duration: 0.45, ease: 'power3.out'}));
      const yTo = cards.map((card) => gsap.quickTo(card, 'y', {duration: 0.45, ease: 'power3.out'}));

      const onMove = (event: MouseEvent) => {
        const stage = heroStageRef.current;
        if (!stage) {
          return;
        }
        const rect = stage.getBoundingClientRect();
        const dx = (event.clientX - rect.left) / rect.width - 0.5;
        const dy = (event.clientY - rect.top) / rect.height - 0.5;
        xTo.forEach((to, index) => to(dx * (index + 1) * 10));
        yTo.forEach((to, index) => to(dy * (index + 1) * 6));
      };

      heroStageRef.current?.addEventListener('mousemove', onMove);

      return () => {
        heroStageRef.current?.removeEventListener('mousemove', onMove);
      };
    }, rootRef);

    return () => context.revert();
  }, []);

  useEffect(() => {
    if (!splitRef.current) {
      return;
    }
    const width = previewMode === 'before' ? 0 : previewMode === 'after' ? 100 : splitPosition;
    gsap.to(splitRef.current, {
      '--split': `${width}%`,
      duration: 0.38,
      ease: 'power2.out',
    });
  }, [previewMode, splitPosition]);

  const activeRoll = rolls[selectedRoll];
  const visibleSplit = previewMode === 'before' ? 0 : previewMode === 'after' ? 100 : splitPosition;
  const applyPreviewStyle = {
    '--intensity-opacity': (intensity / 100).toFixed(2),
    '--intensity-saturation': (1 + intensity * 0.006).toFixed(2),
    '--intensity-contrast': (1 + intensity * 0.0012).toFixed(2),
  } as React.CSSProperties;

  const updateSplitFromPointer = (event: React.PointerEvent<HTMLDivElement>) => {
    const rect = splitPhotoRef.current?.getBoundingClientRect();
    if (!rect) {
      return;
    }
    const nextSplit = clamp(((event.clientX - rect.left) / rect.width) * 100, 4, 96);
    setPreviewMode('split');
    setSplitPosition(Math.round(nextSplit));
  };

  const onSplitPointerDown = (event: React.PointerEvent<HTMLDivElement>) => {
    splitDragPointerRef.current = event.pointerId;
    event.currentTarget.setPointerCapture(event.pointerId);
    updateSplitFromPointer(event);
  };

  const onSplitPointerMove = (event: React.PointerEvent<HTMLDivElement>) => {
    if (splitDragPointerRef.current !== event.pointerId) {
      return;
    }
    updateSplitFromPointer(event);
  };

  const endSplitDrag = (event: React.PointerEvent<HTMLDivElement>) => {
    if (splitDragPointerRef.current !== event.pointerId) {
      return;
    }
    splitDragPointerRef.current = null;
    event.currentTarget.releasePointerCapture(event.pointerId);
  };

  const nudgeSplit = (event: React.KeyboardEvent<HTMLButtonElement>) => {
    if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) {
      return;
    }
    event.preventDefault();
    setPreviewMode('split');
    setSplitPosition((current) => {
      if (event.key === 'Home') {
        return 4;
      }
      if (event.key === 'End') {
        return 96;
      }
      const direction = event.key === 'ArrowLeft' ? -4 : 4;
      return clamp(current + direction, 4, 96);
    });
  };

  const updateIntensityFromPointer = (event: React.PointerEvent<HTMLDivElement>) => {
    const rect = intensityTrackRef.current?.getBoundingClientRect();
    if (!rect) {
      return;
    }
    const nextIntensity = clamp(((event.clientX - rect.left) / rect.width) * 100, 0, 100);
    setIntensity(Math.round(nextIntensity));
  };

  const onIntensityPointerDown = (event: React.PointerEvent<HTMLDivElement>) => {
    intensityDragPointerRef.current = event.pointerId;
    event.currentTarget.setPointerCapture(event.pointerId);
    updateIntensityFromPointer(event);
  };

  const onIntensityPointerMove = (event: React.PointerEvent<HTMLDivElement>) => {
    if (intensityDragPointerRef.current !== event.pointerId) {
      return;
    }
    updateIntensityFromPointer(event);
  };

  const endIntensityDrag = (event: React.PointerEvent<HTMLDivElement>) => {
    if (intensityDragPointerRef.current !== event.pointerId) {
      return;
    }
    intensityDragPointerRef.current = null;
    event.currentTarget.releasePointerCapture(event.pointerId);
  };

  const nudgeIntensity = (event: React.KeyboardEvent<HTMLDivElement>) => {
    if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) {
      return;
    }
    event.preventDefault();
    setIntensity((current) => {
      if (event.key === 'Home') {
        return 0;
      }
      if (event.key === 'End') {
        return 100;
      }
      const direction = event.key === 'ArrowLeft' ? -4 : 4;
      return clamp(current + direction, 0, 100);
    });
  };

  return (
    <div className="site-shell" ref={rootRef}>
      <nav className="site-nav" aria-label="Main navigation">
        <a className="brand-lockup" href="#top" aria-label="LumoRoll home">
          <img src={assets.brand} alt="" />
          <span>LumoRoll</span>
        </a>
        <div className="nav-links" aria-label="Page sections">
          <a href="#rolls">Film Rolls</a>
          <a href="#apply">Apply</a>
          <a href="#privacy">Privacy</a>
          <a className="nav-testflight" href={TESTFLIGHT_URL} target="_blank" rel="noreferrer">
            TestFlight
          </a>
        </div>
      </nav>

      <main id="top">
        <section className="hero-section lr-paper" aria-labelledby="hero-title">
          <div className="hero-copy">
            <p className="mono-line">LOCAL COLOR ROLLS / 33x33x33 .CUBE</p>
            <h1 id="hero-title">LumoRoll</h1>
            <p className="hero-lede">
              Turn one reference photo into a personal Film Roll, apply it to your photos, and export a reusable LUT without sending images to the cloud.
            </p>
            <div className="hero-actions">
              <a className="primary-action" href={TESTFLIGHT_URL} target="_blank" rel="noreferrer">
                <Icon name="phone" />
                Join TestFlight
              </a>
              <a className="secondary-action" href="#rolls">
                <Icon name="film" />
                See the roll
              </a>
            </div>
          </div>

          <div className="hero-stage" ref={heroStageRef} aria-label="Animated Film Roll carousel preview">
            {rolls.map((roll, index) => (
              <button
                key={roll.name}
                className={`hero-card ${carouselPosition(index, selectedRoll)} ${selectedRoll === index ? 'is-selected' : ''}`}
                onClick={() => setSelectedRoll(index)}
                aria-label={`Select ${roll.name}`}
              >
                <SlideCard roll={roll} isSelected={selectedRoll === index} />
              </button>
            ))}
          </div>

          <div className="hero-summary" aria-live="polite">
            <span>{activeRoll.name}</span>
            <small>{activeRoll.count} photos / {activeRoll.date}</small>
            <Palette colors={activeRoll.colors} />
          </div>

          <div className="hero-peek" aria-hidden="true">
            <LightBoxAssembly variant="light" moving={false} compact />
          </div>
        </section>

        <section className="roll-section" id="rolls" aria-labelledby="roll-title">
          <div className="section-copy">
            <p className="mono-line">FILM ROLL DETAIL</p>
            <h2 id="roll-title">The film passes through the light box.</h2>
            <p>
              LumoRoll's detail view is built from the same three-layer object used here: a back frame asset, a finite moving film strip, and the front viewer block.
            </p>
          </div>
          <LightBoxAssembly variant="dark" moving />
        </section>

        <section className="apply-section lr-paper" id="apply" aria-labelledby="apply-title">
          <div className="apply-preview" ref={splitRef} style={applyPreviewStyle}>
            <div className="phone-frame">
              <div className="phone-top">
                <span>{activeRoll.name}</span>
                <small>Intensity {intensity}</small>
              </div>
              <div
                className="split-photo"
                ref={splitPhotoRef}
                onPointerDown={onSplitPointerDown}
                onPointerMove={onSplitPointerMove}
                onPointerUp={endSplitDrag}
                onPointerCancel={endSplitDrag}
              >
                <div className="photo-before" />
                <div className="photo-after" />
                <button
                  className="split-handle"
                  type="button"
                  role="slider"
                  aria-label="Split preview position"
                  aria-valuemin={4}
                  aria-valuemax={96}
                  aria-valuenow={Math.round(visibleSplit)}
                  onKeyDown={nudgeSplit}
                />
              </div>
              <div className="mode-tabs" role="group" aria-label="Preview mode">
                {(['before', 'split', 'after'] as const).map((mode) => (
                  <button
                    key={mode}
                    className={previewMode === mode ? 'active' : ''}
                    onClick={() => setPreviewMode(mode)}
                  >
                    {mode}
                  </button>
                ))}
              </div>
              <div
                className="intensity-control"
                ref={intensityTrackRef}
                role="slider"
                tabIndex={0}
                aria-label="Intensity"
                aria-valuemin={0}
                aria-valuemax={100}
                aria-valuenow={intensity}
                style={{'--value': `${intensity}%`} as React.CSSProperties}
                onPointerDown={onIntensityPointerDown}
                onPointerMove={onIntensityPointerMove}
                onPointerUp={endIntensityDrag}
                onPointerCancel={endIntensityDrag}
                onKeyDown={nudgeIntensity}
              >
                <span className="intensity-fill" />
                <span className="intensity-thumb" />
              </div>
            </div>
          </div>
          <div className="section-copy">
            <p className="mono-line">APPLY</p>
            <h2 id="apply-title">A simple before, split, after flow.</h2>
            <p>
              Intensity blends the original and LUT-processed output. The saved Film Roll LUT stays stable, so changing the slider does not regenerate the roll.
            </p>
          </div>
        </section>

        <section className="privacy-section" id="privacy" aria-labelledby="privacy-title">
          <div className="section-copy">
            <p className="mono-line">EXPORT / PRIVACY</p>
            <h2 id="privacy-title">Made for local creative work.</h2>
          </div>
          <div className="release-grid">
            <ReleasePoint icon="cube" title=".cube export" text="Every Film Roll can export its base LUT as a standard 33x33x33 cube file." />
            <ReleasePoint icon="lock" title="On-device" text="Reference analysis, Algorithm V2, private model-enabled releases, preview, and render paths run locally." />
            <ReleasePoint icon="photo" title="Photos by choice" text="Processed photos write to Photos only from an explicit user action." />
          </div>
        </section>
      </main>
    </div>
  );
}

function SlideCard({roll, isSelected}: {roll: (typeof rolls)[number]; isSelected: boolean}) {
  const photoStyle = {
    '--photo-a': roll.photo[0],
    '--photo-b': roll.photo[1],
    '--photo-c': roll.photo[2],
  } as React.CSSProperties;

  return (
    <div className="slide-card" data-selected={isSelected ? 'true' : 'false'}>
      <div className="slide-head">
        <span>{String(roll.serial).padStart(3, '0')}</span>
        <strong>{roll.name.toUpperCase()}</strong>
        <i />
      </div>
      <p>COLOR ROLL</p>
      <div className="slide-window" style={photoStyle}>
        <div className="synthetic-photo" />
      </div>
      <div className="slide-foot">
        <span>LUT</span>
        <div>
          <Palette colors={roll.colors} />
          <span>33x33x33</span>
        </div>
      </div>
    </div>
  );
}

function LightBoxAssembly({variant, moving, compact = false}: {variant: 'light' | 'dark'; moving: boolean; compact?: boolean}) {
  const frameAsset = variant === 'dark' ? assets.backFrameDark : assets.backFrame;
  const frontAsset = variant === 'dark' ? assets.frontBlockDark : assets.frontBlock;
  const framePalette = useMemo(() => detailFrames.concat(detailFrames), []);

  return (
    <div className={`lightbox-assembly ${variant} ${compact ? 'compact' : ''}`} aria-label="Layered Film Roll light box">
      <img className="lightbox-back" src={frameAsset} alt="" />
      <div className={`film-track ${moving ? 'motion' : ''}`}>
        <div className="sprockets top" />
        <div className="film-frames">
          <span className="leader" />
          {framePalette.map((colors, index) => (
            <div
              className="film-cell"
              key={`${colors.join('-')}-${index}`}
              style={{
                '--photo-a': colors[0],
                '--photo-b': colors[1],
                '--photo-c': colors[2],
              } as React.CSSProperties}
            >
              <div className="synthetic-photo" />
            </div>
          ))}
          <span className="leader" />
        </div>
        <div className="sprockets bottom" />
      </div>
      <img className="lightbox-front" src={frontAsset} alt="" />
    </div>
  );
}

function Palette({colors}: {colors: string[]}) {
  return (
    <span className="palette" aria-hidden="true">
      {colors.map((color) => (
        <i key={color} style={{background: color}} />
      ))}
    </span>
  );
}

function ReleasePoint({icon, title, text}: {icon: IconName; title: string; text: string}) {
  return (
    <article className="release-point">
      <Icon name={icon} />
      <h3>{title}</h3>
      <p>{text}</p>
    </article>
  );
}

type IconName = 'film' | 'shield' | 'cube' | 'lock' | 'photo' | 'phone';

function carouselPosition(index: number, selectedIndex: number) {
  const count = rolls.length;
  const normalized = (index - selectedIndex + count) % count;
  if (normalized === 0) {
    return 'card-center';
  }
  if (normalized === 1) {
    return 'card-right';
  }
  return 'card-left';
}

function clamp(value: number, min: number, max: number) {
  return Math.min(Math.max(value, min), max);
}

function Icon({name}: {name: IconName}) {
  const paths: Record<IconName, string> = {
    film: 'M4 5h16v14H4z M7 5v14 M17 5v14 M4 9h3 M4 15h3 M17 9h3 M17 15h3',
    shield: 'M12 3l7 3v5c0 5-3.5 8-7 10-3.5-2-7-5-7-10V6l7-3z',
    cube: 'M12 3l8 4.5v9L12 21l-8-4.5v-9L12 3z M12 12l8-4.5 M12 12v9 M12 12L4 7.5',
    lock: 'M7 11V8a5 5 0 0110 0v3 M6 11h12v9H6z',
    photo: 'M4 6h16v12H4z M7 15l3-3 2 2 3-4 3 5 M8 9h.01',
    phone: 'M8 3h8a2 2 0 012 2v14a2 2 0 01-2 2H8a2 2 0 01-2-2V5a2 2 0 012-2z M10 6h4 M11 18h2',
  };

  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d={paths[name]} />
    </svg>
  );
}

export default App;
