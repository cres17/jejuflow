// jf-home.jsx — Home screen: weather hero + draggable bottom sheet + swipeable spot stack

const { useState: useS, useRef: useR, useEffect: useE, useMemo: useM } = React;

// ─────────────────────────────────────────────────────────────
// SUN ARC — interactive time-of-day arc.
// User drags the sun along the arc; weather/temp morph.
// ─────────────────────────────────────────────────────────────
const SunArc = ({ weather, hour, onHour, lang }) => {
  const t = I18N[lang];
  const w = WEATHERS[weather];
  // arc geometry
  const W = 364, H = 140;
  const cx = W/2, cy = 130, R = 130;
  // hour 6→20 mapped to angle 180→0 (deg)
  const norm = Math.max(6, Math.min(20, hour));
  const ang = (180 - ((norm - 6) / 14) * 180) * Math.PI / 180;
  const sx = cx + Math.cos(ang) * R;
  const sy = cy - Math.sin(ang) * R;

  const dragRef = useR(false);
  const handlePointer = (e) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const px = (e.touches?.[0]?.clientX ?? e.clientX) - rect.left;
    const py = (e.touches?.[0]?.clientY ?? e.clientY) - rect.top;
    const dx = px - cx;
    const dy = cy - py;
    let a = Math.atan2(dy, dx); // 0 = right, π/2 = up
    if (a < 0) a = 0;
    if (a > Math.PI) a = Math.PI;
    const newHour = 6 + ((Math.PI - a) / Math.PI) * 14;
    onHour(Math.round(newHour * 2) / 2);
  };

  const tempLabel = w.temp + '°';
  return (
    <div style={{ position: 'relative', width: '100%', height: 170, userSelect: 'none' }}
      onPointerDown={(e) => { dragRef.current = true; e.currentTarget.setPointerCapture(e.pointerId); handlePointer(e); }}
      onPointerMove={(e) => { if (dragRef.current) handlePointer(e); }}
      onPointerUp={() => dragRef.current = false}>
      <svg width={W} height={H+20} viewBox={`0 0 ${W} ${H+20}`} style={{ display: 'block', margin: '0 auto' }}>
        <defs>
          <linearGradient id="sunArcGrad" x1="0" x2="1">
            <stop offset="0%" stopColor={EG.outlineV} stopOpacity="0.5"/>
            <stop offset="50%" stopColor={EG.tertiary} stopOpacity="0.7"/>
            <stop offset="100%" stopColor={EG.outlineV} stopOpacity="0.5"/>
          </linearGradient>
        </defs>
        {/* horizon */}
        <line x1={cx - R} y1={cy} x2={cx + R} y2={cy} stroke={EG.outlineV} strokeWidth="0.6" strokeDasharray="3 3"/>
        {/* arc */}
        <path d={`M ${cx - R} ${cy} A ${R} ${R} 0 0 1 ${cx + R} ${cy}`} fill="none"
          stroke="url(#sunArcGrad)" strokeWidth="1.5" />
        {/* hour ticks */}
        {[6, 9, 12, 15, 18].map(h => {
          const a = (180 - ((h - 6) / 14) * 180) * Math.PI / 180;
          const tx = cx + Math.cos(a) * (R - 8);
          const ty = cy - Math.sin(a) * (R - 8);
          const tx2 = cx + Math.cos(a) * (R + 4);
          const ty2 = cy - Math.sin(a) * (R + 4);
          return (
            <g key={h}>
              <line x1={tx} y1={ty} x2={tx2} y2={ty2} stroke={EG.outline} strokeWidth="0.6" opacity="0.55"/>
              <text x={cx + Math.cos(a) * (R + 16)} y={cy - Math.sin(a) * (R + 16) + 4}
                textAnchor="middle" fontSize="9" fill={EG.outline} fontFamily={FONT_MONO}>
                {String(h).padStart(2,'0')}
              </text>
            </g>
          );
        })}
        {/* sun handle */}
        <circle cx={sx} cy={sy} r="14" fill={EG.surface} stroke={EG.tertiary} strokeWidth="2"/>
        <circle cx={sx} cy={sy} r="4" fill={EG.tertiary}/>
      </svg>
      {/* big temp / hour readout */}
      <div style={{ position: 'absolute', top: 28, left: 0, right: 0, textAlign: 'center',
        fontFamily: FONT_DISPLAY, color: EG.ink }}>
        <div style={{ fontSize: 56, fontWeight: 700, letterSpacing: '-0.04em', lineHeight: 1 }}>
          {tempLabel}
        </div>
        <div style={{ marginTop: 4, fontFamily: FONT_BODY, fontSize: 13, color: EG.ink2 }}>
          {String(Math.floor(hour)).padStart(2,'0')}:{Math.round((hour % 1) * 60).toString().padStart(2,'0')} · {w.glyph} {w.label[lang]}
        </div>
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// SWIPE STACK — vertical card stack. Up = add to route, Down = skip.
// ─────────────────────────────────────────────────────────────
const SwipeStack = ({ spots, lang, onAdd, onSkip, addedIds = [], focused }) => {
  const t = I18N[lang];
  const [topIdx, setTopIdx] = useS(0);
  const [drag, setDrag] = useS({ y: 0, dragging: false });
  const [flash, setFlash] = useS(null); // 'added' | 'skipped'

  useE(() => { setTopIdx(0); }, [spots.length, focused]);

  const cards = useM(() => spots.slice(topIdx, topIdx + 3), [spots, topIdx]);
  const top = cards[0];
  if (!top) {
    return (
      <div style={{ height: 380, display: 'flex', flexDirection: 'column', alignItems: 'center',
        justifyContent: 'center', gap: 12, color: EG.ink2, fontFamily: FONT_BODY }}>
        <div style={{ fontFamily: FONT_DISPLAY, fontWeight: 600, fontSize: 22, color: EG.ink, letterSpacing: '-0.02em' }}>
          {lang === 'ko' ? '오늘의 흐름 완성!' : lang === 'en' ? "Flow complete!" : lang === 'ja' ? '完成!' : '完成!'}
        </div>
        <div style={{ fontSize: 13, color: EG.ink2 }}>
          {lang === 'ko' ? '여정 탭에서 확인하세요' : lang === 'en' ? 'Check the Route tab' : lang === 'ja' ? 'ルートタブで確認' : '在路线标签中查看'}
        </div>
        <div style={{ marginTop: 8 }}>
          <PillButton size="sm" kind="ghost" onClick={() => setTopIdx(0)}>
            {lang === 'ko' ? '다시 보기' : 'Restart'}
          </PillButton>
        </div>
      </div>
    );
  }

  const dragStart = useR(0);
  const handleDown = (e) => { dragStart.current = e.touches?.[0]?.clientY ?? e.clientY; setDrag({ y: 0, dragging: true }); };
  const handleMove = (e) => {
    if (!drag.dragging) return;
    const y = (e.touches?.[0]?.clientY ?? e.clientY) - dragStart.current;
    setDrag({ y, dragging: true });
  };
  const handleUp = () => {
    const threshold = 80;
    if (drag.y < -threshold) {
      setFlash('added'); onAdd && onAdd(top.id);
      setTimeout(() => setFlash(null), 450);
      setDrag({ y: -400, dragging: false });
      setTimeout(() => { setTopIdx(i => i + 1); setDrag({ y: 0, dragging: false }); }, 240);
    } else if (drag.y > threshold) {
      setFlash('skipped'); onSkip && onSkip(top.id);
      setTimeout(() => setFlash(null), 450);
      setDrag({ y: 400, dragging: false });
      setTimeout(() => { setTopIdx(i => i + 1); setDrag({ y: 0, dragging: false }); }, 240);
    } else {
      setDrag({ y: 0, dragging: false });
    }
  };

  return (
    <div style={{ position: 'relative', height: 420, padding: '0 24px', userSelect: 'none' }}>
      {/* progress dots */}
      <div style={{ display: 'flex', justifyContent: 'center', gap: 4, marginBottom: 12 }}>
        {spots.map((_, i) => (
          <span key={i} style={{ width: i === topIdx ? 18 : 4, height: 4, borderRadius: 2,
            background: i < topIdx ? EG.primary : i === topIdx ? EG.tertiary : EG.outlineV,
            transition: 'all 0.3s' }} />
        ))}
      </div>

      {cards.slice().reverse().map((s, ridx) => {
        const i = cards.length - 1 - ridx; // 0 is top, 1 second, 2 third
        const isTop = i === 0;
        const offsetY = i * 14;
        const scale = 1 - i * 0.04;
        const opacity = i === 2 ? 0.55 : 1;
        const dy = isTop ? drag.y : 0;
        const rotate = isTop ? Math.max(-6, Math.min(6, drag.y / 30)) : 0;
        const transition = drag.dragging ? 'none' : 'transform 0.32s cubic-bezier(.2,.7,.3,1.2), opacity 0.2s';
        return (
          <div key={s.id + i} style={{
            position: 'absolute', left: 24, right: 24, top: 18 + offsetY,
            transform: `translateY(${dy}px) scale(${scale}) rotate(${rotate}deg)`,
            transition,
            opacity,
            zIndex: 10 - i,
          }}
          onPointerDown={isTop ? handleDown : undefined}
          onPointerMove={isTop ? handleMove : undefined}
          onPointerUp={isTop ? handleUp : undefined}
          onPointerCancel={isTop ? handleUp : undefined}>
            <SpotCard spot={s} lang={lang} dy={isTop ? dy : 0} added={addedIds.includes(s.id)} />
          </div>
        );
      })}

      {/* swipe affordances */}
      <div style={{ position: 'absolute', bottom: -28, left: 0, right: 0, display: 'flex',
        justifyContent: 'space-between', padding: '0 32px', pointerEvents: 'none' }}>
        <div style={{ fontFamily: FONT_MONO, fontSize: 10, color: EG.outline, letterSpacing: '0.08em' }}>
          ↓ {lang === 'ko' ? '건너뛰기' : 'skip'}
        </div>
        <div style={{ fontFamily: FONT_MONO, fontSize: 10, color: EG.tertiary, letterSpacing: '0.08em', fontWeight: 600 }}>
          ↑ {t.swipeUp}
        </div>
      </div>

      {/* flash message */}
      {flash && (
        <div style={{
          position: 'absolute', top: '40%', left: '50%', transform: 'translate(-50%, -50%)',
          padding: '14px 26px', borderRadius: 999,
          background: flash === 'added' ? EG.primary : EG.inverseSurface,
          color: '#fff', fontFamily: FONT_DISPLAY, fontWeight: 600, fontSize: 16,
          letterSpacing: '-0.01em', zIndex: 30,
          animation: 'jfPop 0.45s cubic-bezier(.2,.7,.3,1.2)',
        }}>
          {flash === 'added' ? '✓ ' + t.added : '↓ skip'}
        </div>
      )}
    </div>
  );
};

const SpotCard = ({ spot, lang, dy = 0, added }) => {
  const t = I18N[lang];
  const upGlow = Math.max(0, -dy) / 200;
  const downGlow = Math.max(0, dy) / 200;
  return (
    <div style={{
      background: EG.surfaceLow, borderRadius: 32, padding: 18,
      boxShadow: `0 18px 40px rgba(28,28,24,${0.10 + Math.abs(dy)/1500}), 0 0 0 1px ${EG.outlineV}`,
      fontFamily: FONT_BODY, color: EG.ink,
      borderTop: upGlow > 0 ? `2px solid rgba(75,100,80,${upGlow})` : 'none',
      borderBottom: downGlow > 0 ? `2px solid rgba(117,120,115,${downGlow})` : 'none',
    }}>
      <SpotImg spot={spot} height={170} radius={24} />
      <div style={{ marginTop: 14, display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 10 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontFamily: FONT_DISPLAY, fontWeight: 700, fontSize: 22, letterSpacing: '-0.02em', color: EG.ink, lineHeight: 1.1 }}>
            {spot.name[lang]}
          </div>
          <div style={{ fontSize: 12, color: EG.ink2, marginTop: 4, lineHeight: 1.4 }}>
            {spot.blurb[lang]}
          </div>
        </div>
        {added && (
          <span style={{ flexShrink: 0, padding: '6px 10px', borderRadius: 999,
            background: EG.primaryC, color: EG.onPrimaryC, fontSize: 10, fontWeight: 700, letterSpacing: '0.04em' }}>
            ✓ {t.added}
          </span>
        )}
      </div>
      <div style={{ marginTop: 14, display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap' }}>
        <Chip kind="primary">{t['kind' + spot.kind.charAt(0).toUpperCase() + spot.kind.slice(1)] || spot.kind}</Chip>
        <Chip kind="outline">🚏 {t.busLine(spot.busLine)}</Chip>
        <BusTicker minutes={spot.busIn} line={spot.busLine} lang={lang} />
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// HOME — assembles SunArc + SwipeStack + draggable map peek
// ─────────────────────────────────────────────────────────────
const HomeScreen = ({ weather, lang, hour, setHour, route, addRoute, removeRoute, onOpenSpot }) => {
  const t = I18N[lang];
  const w = WEATHERS[weather];
  const indoor = weather === 'rain' || weather === 'wind';
  const recommended = useM(() => SPOTS.filter(s => indoor ? s.indoor : !s.indoor), [indoor]);
  const because = ({ rain: t.becauseRain, wind: t.becauseWind, cloudy: t.becauseCloud, sunny: t.becauseSun })[weather];

  // bg morph color
  const bg = mix(EG.surface, w.tint, 0.06);
  const sky = mix(w.sky1, w.sky2, 0.4);

  return (
    <div style={{ position: 'absolute', inset: 0, background: bg, overflowY: 'auto',
      transition: 'background 0.6s ease' }}>
      {/* atmospheric sky band */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: 360,
        background: `linear-gradient(180deg, ${w.sky1} 0%, ${w.sky2} 70%, ${bg} 100%)`,
        transition: 'background 0.6s ease' }}>
        {weather === 'rain' && <RainOverlay/>}
        {weather === 'wind' && <WindOverlay/>}
        {weather === 'cloudy' && <CloudOverlay/>}
        {weather === 'sunny' && <SunOverlay/>}
      </div>

      <div style={{ position: 'relative', zIndex: 2 }}>
        <StatusBar />

        {/* header */}
        <div style={{ padding: '6px 24px 0', display: 'flex', justifyContent: 'space-between',
          alignItems: 'center', fontFamily: FONT_BODY }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', color: EG.ink2,
              textTransform: 'uppercase' }}>{t.appName}</div>
            <div style={{ fontSize: 12, color: EG.ink2, marginTop: 2 }}>{t.nowAt}</div>
          </div>
          <div style={{ display: 'inline-flex', gap: 6, alignItems: 'center', padding: '6px 12px',
            borderRadius: 999, background: 'rgba(252,249,242,0.7)', backdropFilter: 'blur(10px)',
            border: `1px solid ${EG.outlineV}`, whiteSpace: 'nowrap', flexShrink: 0 }}>
            <span style={{ width: 8, height: 8, borderRadius: '50%', background: EG.tertiary, flexShrink: 0 }} />
            <span style={{ fontSize: 11, fontWeight: 600, color: EG.ink, whiteSpace: 'nowrap' }}>
              {indoor ? t.forIndoor : t.forOutdoor}
            </span>
          </div>
        </div>

        {/* SunArc */}
        <div style={{ marginTop: 10 }}>
          <SunArc weather={weather} hour={hour} onHour={setHour} lang={lang} />
        </div>

        {/* because line */}
        <div style={{ padding: '14px 32px 4px', textAlign: 'center', fontFamily: FONT_BODY,
          fontSize: 14, color: EG.ink2, letterSpacing: '-0.01em' }}>
          {because}
        </div>

        {/* hint */}
        <div style={{ padding: '14px 24px 4px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', gap: 12 }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: FONT_DISPLAY, fontWeight: 700, fontSize: 26, letterSpacing: '-0.02em', color: EG.ink, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {t.flowFor}
            </div>
            <div style={{ fontSize: 12, color: EG.ink2, marginTop: 2 }}>
              {t.swipeHint} · {recommended.length} {t.spotsCount(recommended.length).replace(/\d+/, '').trim()}
            </div>
          </div>
          <span style={{ fontFamily: FONT_MONO, fontSize: 11, color: EG.outline }}>
            {route.length} / {recommended.length}
          </span>
        </div>

        {/* swipe stack */}
        <div style={{ marginTop: 10 }}>
          <SwipeStack
            spots={recommended}
            lang={lang}
            addedIds={route.map(r => r.id)}
            focused={weather}
            onAdd={(id) => addRoute(id)}
            onSkip={() => {}}
          />
        </div>

        <div style={{ height: 130 }} />
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// Weather overlays
// ─────────────────────────────────────────────────────────────
const RainOverlay = () => (
  <svg width="100%" height="360" viewBox="0 0 412 360" preserveAspectRatio="none"
    style={{ position: 'absolute', inset: 0, opacity: 0.22 }}>
    {Array.from({ length: 24 }).map((_, i) => {
      const x = (i * 53 + 11) % 412;
      const y = (i * 89 + 17) % 360;
      return <line key={i} x1={x} y1={y} x2={x - 4} y2={y + 14} stroke="#5A7E96" strokeWidth="1"/>;
    })}
  </svg>
);
const WindOverlay = () => (
  <svg width="100%" height="360" viewBox="0 0 412 360" preserveAspectRatio="none"
    style={{ position: 'absolute', inset: 0, opacity: 0.22 }}>
    {[60, 150, 240].map((y, i) => (
      <path key={i} d={`M -20 ${y} Q 200 ${y - 30 + i*10}, 432 ${y + 10}`} fill="none" stroke={EG.primary} strokeWidth="0.8"/>
    ))}
  </svg>
);
const CloudOverlay = () => (
  <div style={{ position: 'absolute', inset: 0,
    background: 'radial-gradient(ellipse 320px 160px at 80% 12%, rgba(255,255,255,0.5), transparent 70%), radial-gradient(ellipse 240px 120px at 18% 36%, rgba(255,255,255,0.4), transparent 70%)' }} />
);
const SunOverlay = () => (
  <div style={{ position: 'absolute', inset: 0,
    background: 'radial-gradient(circle 200px at 85% 8%, rgba(255,181,151,0.35), transparent 70%)' }} />
);

Object.assign(window, { HomeScreen, SunArc, SwipeStack, SpotCard });
