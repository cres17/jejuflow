// jf-screens.jsx — Explore, Route, Settings, Spot detail sheet, Onboarding

const { useState: useSt, useEffect: useEf, useRef: useRf, useMemo: useMm } = React;

// ─────────────────────────────────────────────────────────────
// EXPLORE — live map + draggable bottom sheet
// Sheet has 3 snap points: peek (140), mid (430), full (760).
// ─────────────────────────────────────────────────────────────
const ExploreScreen = ({ weather, lang, route, addRoute, onOpenSpot }) => {
  const t = I18N[lang];
  const SNAPS = [140, 430, 760]; // px from bottom
  const [snap, setSnap] = useSt(1);
  const [drag, setDrag] = useSt(0);
  const [filter, setFilter] = useSt('all');
  const [hover, setHover] = useSt(null);

  const filters = [
    { id: 'all', label: lang === 'ko' ? '전체' : lang === 'en' ? 'All' : lang === 'ja' ? 'すべて' : '全部' },
    { id: 'coast', label: t.kindCoast },
    { id: 'oreum', label: t.kindOreum },
    { id: 'olle', label: t.kindOlle },
    { id: 'museum', label: t.kindMuseum },
    { id: 'cafe', label: lang === 'ko' ? '카페' : lang === 'en' ? 'Cafe' : lang === 'ja' ? 'カフェ' : '咖啡' },
  ];
  const list = useMm(() => SPOTS.filter(s => filter === 'all' || s.kind === filter), [filter]);

  const dragStartY = useRf(0);
  const handleDown = (e) => { dragStartY.current = e.touches?.[0]?.clientY ?? e.clientY; setDrag(0); };
  const handleMove = (e) => {
    const y = (e.touches?.[0]?.clientY ?? e.clientY) - dragStartY.current;
    setDrag(y);
  };
  const handleUp = () => {
    const cur = SNAPS[snap] - drag;
    let best = 0; let bestDist = Infinity;
    SNAPS.forEach((v, i) => { const d = Math.abs(v - cur); if (d < bestDist) { bestDist = d; best = i; } });
    setSnap(best);
    setDrag(0);
  };

  const sheetH = SNAPS[snap] - drag;

  return (
    <div style={{ position: 'absolute', inset: 0, background: EG.surface, overflow: 'hidden' }}>
      {/* MAP fills frame */}
      <div style={{ position: 'absolute', inset: 0 }}>
        <JejuMap spots={list} weather={weather} highlightId={hover}
          onPickSpot={(id) => onOpenSpot(id)} dim={1} />
      </div>

      <div style={{ position: 'relative', zIndex: 5 }}>
        <StatusBar />
        {/* search/filter bar floating */}
        <div style={{ padding: '6px 16px 12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8,
            background: 'rgba(252,249,242,0.92)', backdropFilter: 'blur(14px)',
            border: `1px solid ${EG.outlineV}`, borderRadius: 999, padding: '0 6px 0 14px', height: 48,
            boxShadow: '0 6px 24px rgba(28,28,24,0.06)' }}>
            <svg width="16" height="16" viewBox="0 0 14 14"><circle cx="6" cy="6" r="4.5" fill="none" stroke={EG.ink} strokeWidth="1.4"/><line x1="9" y1="9" x2="12" y2="12" stroke={EG.ink} strokeWidth="1.4" strokeLinecap="round"/></svg>
            <input placeholder={lang === 'ko' ? '관광지, 정류장 찾기' : lang === 'en' ? 'Search spots, stops' : lang === 'ja' ? 'スポット検索' : '搜索景点'}
              style={{ flex: 1, border: 'none', outline: 'none', background: 'transparent',
                fontFamily: FONT_BODY, fontSize: 14, color: EG.ink }} />
            <span style={{ width: 36, height: 36, borderRadius: '50%', background: EG.primary, color: '#fff',
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 14, fontWeight: 700 }}>
              {WEATHERS[weather].glyph}
            </span>
          </div>
        </div>

        {/* filter chips horizontal scroll */}
        <div style={{ padding: '0 0 0 16px', overflowX: 'auto', whiteSpace: 'nowrap', scrollbarWidth: 'none' }}>
          {filters.map(f => (
            <span key={f.id} onClick={() => setFilter(f.id)} style={{ marginRight: 6 }}>
              <Chip active={filter === f.id} kind={filter === f.id ? 'primary' : 'default'}>{f.label}</Chip>
            </span>
          ))}
        </div>
      </div>

      {/* layer controls — right side */}
      <div style={{ position: 'absolute', right: 16, top: 200, zIndex: 4, display: 'flex', flexDirection: 'column', gap: 6 }}>
        <CircleBtn label="+"/>
        <CircleBtn label="−"/>
        <div style={{ height: 8 }}/>
        <CircleBtn label="◎" tone="primary"/>
      </div>

      {/* DRAGGABLE BOTTOM SHEET */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: sheetH,
        background: EG.surface, borderRadius: '32px 32px 0 0',
        boxShadow: '0 -16px 40px rgba(28,28,24,0.10)',
        transition: drag ? 'none' : 'height 0.3s cubic-bezier(.2,.7,.3,1)',
        overflow: 'hidden', zIndex: 6,
      }}>
        {/* drag handle */}
        <div onPointerDown={(e) => { e.currentTarget.setPointerCapture(e.pointerId); handleDown(e); }}
             onPointerMove={(e) => e.currentTarget.hasPointerCapture(e.pointerId) && handleMove(e)}
             onPointerUp={(e) => { e.currentTarget.releasePointerCapture(e.pointerId); handleUp(); }}
             style={{ padding: '12px 0 8px', cursor: 'grab', touchAction: 'none' }}>
          <div style={{ width: 38, height: 4, borderRadius: 2, background: EG.outlineV, margin: '0 auto' }}/>
        </div>

        {/* sheet content */}
        <div style={{ padding: '0 24px', height: sheetH - 28, overflowY: 'auto' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
            <div style={{ fontFamily: FONT_DISPLAY, fontWeight: 700, fontSize: 22, letterSpacing: '-0.02em', color: EG.ink }}>
              {filter === 'all' ? t.explore : t['kind' + filter.charAt(0).toUpperCase() + filter.slice(1)] || filter}
            </div>
            <span style={{ fontFamily: FONT_MONO, fontSize: 11, color: EG.outline }}>
              {list.length} · {t.kmDown}
            </span>
          </div>

          {list.map(s => (
            <div key={s.id} onClick={() => onOpenSpot(s.id)}
              onMouseEnter={() => setHover(s.id)} onMouseLeave={() => setHover(null)}
              style={{ display: 'flex', gap: 14, padding: '12px 0', borderBottom: `1px solid ${EG.surfaceCt}`,
                cursor: 'pointer', fontFamily: FONT_BODY }}>
              <SpotImg spot={s} height={76} radius={18} style={{ width: 100, flexShrink: 0 }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>
                  <span style={{ fontFamily: FONT_DISPLAY, fontWeight: 600, fontSize: 16, color: EG.ink, letterSpacing: '-0.01em' }}>
                    {s.name[lang]}
                  </span>
                  {route.find(r => r.id === s.id) && (
                    <span style={{ flexShrink: 0, fontSize: 10, fontWeight: 700, color: EG.onPrimaryC,
                      background: EG.primaryC, padding: '3px 8px', borderRadius: 999 }}>✓</span>
                  )}
                </div>
                <div style={{ fontSize: 12, color: EG.ink2, marginTop: 2 }}>{s.blurb[lang]}</div>
                <div style={{ marginTop: 6, display: 'flex', alignItems: 'center', gap: 10 }}>
                  <BusTicker minutes={s.busIn} line={s.busLine} lang={lang} />
                  <span style={{ fontFamily: FONT_MONO, fontSize: 11, color: EG.outline }}>· {s.walk}m walk</span>
                </div>
              </div>
            </div>
          ))}
          <div style={{ height: 100 }} />
        </div>
      </div>
    </div>
  );
};

const CircleBtn = ({ label, tone = 'surface', onClick }) => {
  const bg = tone === 'primary' ? EG.primary : 'rgba(252,249,242,0.92)';
  const fg = tone === 'primary' ? '#fff' : EG.ink;
  return (
    <button onClick={onClick} style={{
      width: 44, height: 44, borderRadius: '50%', border: `1px solid ${EG.outlineV}`,
      background: bg, color: fg, fontSize: 18, fontWeight: 600, fontFamily: FONT_BODY,
      cursor: 'pointer', backdropFilter: 'blur(10px)',
      boxShadow: '0 4px 12px rgba(28,28,24,0.08)',
    }}>{label}</button>
  );
};

// ─────────────────────────────────────────────────────────────
// ROUTE — drag-reorder list, live counters, "leave by" countdown
// ─────────────────────────────────────────────────────────────
const RouteScreen = ({ weather, lang, route, removeRoute, reorderRoute, hour }) => {
  const t = I18N[lang];
  // compute itinerary times starting from current hour
  const items = useMm(() => {
    let cur = hour;
    return route.map((s, i) => {
      const arrive = cur;
      const stay = i === route.length - 1 ? 1.5 : 1.5;
      cur = cur + stay + 0.5;
      return { ...s, arrive, stay };
    });
  }, [route, hour]);
  const fmt = (h) => {
    const hh = Math.floor(h);
    const mm = Math.round((h - hh) * 60);
    return `${String(hh).padStart(2,'0')}:${String(mm).padStart(2,'0')}`;
  };
  const totalH = items.length ? Math.max(0, items[items.length - 1].arrive + items[items.length - 1].stay - hour) : 0;

  return (
    <div style={{ position: 'absolute', inset: 0, background: EG.surface, overflowY: 'auto' }}>
      <StatusBar/>
      <div style={{ padding: '6px 24px 14px', fontFamily: FONT_BODY }}>
        <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', color: EG.ink2, textTransform: 'uppercase' }}>
          {t.todayRoute}
        </span>
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', marginTop: 12 }}>
          <div style={{ fontFamily: FONT_DISPLAY, fontWeight: 700, fontSize: 40, letterSpacing: '-0.03em', lineHeight: 1, color: EG.ink }}>
            {items.length} <span style={{ fontSize: 16, fontWeight: 500, color: EG.ink2, marginLeft: 4 }}>{t.spotsCount(items.length).replace(/\d+/, '').trim()}</span>
          </div>
          <div style={{ textAlign: 'right' }}>
            <div style={{ fontFamily: FONT_MONO, fontSize: 11, color: EG.outline }}>{t.allDay}</div>
            <div style={{ fontFamily: FONT_DISPLAY, fontWeight: 700, fontSize: 18, color: EG.ink, letterSpacing: '-0.01em' }}>
              {totalH.toFixed(1)}h
            </div>
          </div>
        </div>
      </div>

      {/* compact map preview */}
      <div style={{ margin: '0 24px 18px', height: 160, borderRadius: 24, overflow: 'hidden',
        background: EG.surfaceCt, position: 'relative', border: `1px solid ${EG.outlineV}` }}>
        <JejuMap spots={items.map(it => SPOTS.find(s => s.id === it.id))} weather={weather}
          showRoute route={items} dim={1} />
        <div style={{ position: 'absolute', top: 12, left: 14, padding: '4px 10px', background: 'rgba(252,249,242,0.92)',
          borderRadius: 999, fontFamily: FONT_MONO, fontSize: 10, color: EG.ink, fontWeight: 600, letterSpacing: '0.04em' }}>
          {t.mapView.toUpperCase()}
        </div>
      </div>

      {items.length === 0 && (
        <div style={{ margin: '0 24px', padding: '32px 22px', borderRadius: 24, background: EG.surfaceLow,
          border: `1px dashed ${EG.outlineV}`, textAlign: 'center', fontFamily: FONT_BODY }}>
          <div style={{ fontFamily: FONT_DISPLAY, fontWeight: 600, fontSize: 18, color: EG.ink, letterSpacing: '-0.02em' }}>
            {lang === 'ko' ? '아직 비어있어요' : lang === 'en' ? 'Empty for now' : lang === 'ja' ? 'まだ空です' : '尚为空'}
          </div>
          <div style={{ fontSize: 13, color: EG.ink2, marginTop: 6 }}>
            {lang === 'ko' ? '홈에서 카드를 위로 스와이프해 추가하세요' : lang === 'en' ? 'Swipe a card up on Home to add' : lang === 'ja' ? 'ホームでカードを上にスワイプ' : '在首页上滑卡片添加'}
          </div>
        </div>
      )}

      {/* timeline */}
      <div style={{ padding: '0 24px 100px', position: 'relative', fontFamily: FONT_BODY }}>
        {items.map((it, i) => (
          <div key={it.id} style={{ position: 'relative' }}>
            <div style={{ display: 'flex', gap: 14 }}>
              <div style={{ width: 56, flexShrink: 0, paddingTop: 4, textAlign: 'right' }}>
                <div style={{ fontFamily: FONT_MONO, fontSize: 13, fontWeight: 700, color: EG.ink }}>{fmt(it.arrive)}</div>
                <div style={{ fontSize: 10, color: EG.outline, marginTop: 1 }}>+{Math.round(it.stay * 60)}m</div>
              </div>
              <div style={{ position: 'relative', width: 22, flexShrink: 0 }}>
                <div style={{ position: 'absolute', top: 8, left: 9, width: 12, height: 12, borderRadius: '50%',
                  background: i === 0 ? EG.tertiary : EG.surface, border: `2px solid ${EG.primary}`, zIndex: 2 }} />
                {i < items.length - 1 && (
                  <div style={{ position: 'absolute', top: 24, left: 14, bottom: -8, width: 2,
                    background: `repeating-linear-gradient(180deg, ${EG.outlineV} 0 4px, transparent 4px 8px)` }} />
                )}
              </div>
              <div style={{ flex: 1, paddingBottom: 18 }}>
                <div style={{ background: EG.surfaceLow, borderRadius: 24, padding: 16, position: 'relative' }}>
                  <div style={{ display: 'flex', gap: 12 }}>
                    <SpotImg spot={it} height={60} radius={14} style={{ width: 72, flexShrink: 0 }} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontFamily: FONT_DISPLAY, fontWeight: 600, fontSize: 16,
                        letterSpacing: '-0.01em', color: EG.ink }}>{it.name[lang]}</div>
                      <div style={{ fontSize: 11, color: EG.ink2, marginTop: 2 }}>
                        {t['kind' + it.kind.charAt(0).toUpperCase() + it.kind.slice(1)] || it.kind}
                      </div>
                      <div style={{ marginTop: 6 }}>
                        <BusTicker minutes={it.busIn} line={it.busLine} lang={lang}/>
                      </div>
                    </div>
                    <button onClick={() => removeRoute(it.id)}
                      style={{ position: 'absolute', top: 12, right: 14, width: 24, height: 24,
                        borderRadius: '50%', border: 'none', background: EG.surfaceCt, color: EG.ink2,
                        fontSize: 14, cursor: 'pointer', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
                      ×
                    </button>
                  </div>
                </div>
              </div>
            </div>
            {i < items.length - 1 && (
              <div style={{ marginLeft: 92, paddingLeft: 14, paddingBottom: 12,
                fontFamily: FONT_MONO, fontSize: 10, color: EG.outline, letterSpacing: '0.04em' }}>
                ▾ {t.riding} 18m · {t.walking} 6m
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────
// SETTINGS
// ─────────────────────────────────────────────────────────────
const SettingsScreen = ({ lang, setLang, userType, setUserType, dark, setDark }) => {
  const t = I18N[lang];
  const langs = [
    { code: 'ko', label: '한국어', sub: 'Korean' },
    { code: 'en', label: 'English', sub: 'English' },
    { code: 'ja', label: '日本語', sub: 'Japanese' },
    { code: 'zh', label: '中文', sub: 'Chinese' },
  ];
  return (
    <div style={{ position: 'absolute', inset: 0, background: EG.surface, overflowY: 'auto' }}>
      <StatusBar/>
      <div style={{ padding: '6px 24px 28px', fontFamily: FONT_BODY }}>
        <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', color: EG.ink2, textTransform: 'uppercase' }}>
          {t.settings}
        </span>
        <div style={{ marginTop: 14, fontFamily: FONT_DISPLAY, fontWeight: 700, fontSize: 40,
          letterSpacing: '-0.03em', color: EG.ink, lineHeight: 1.05 }}>
          {lang === 'ko' ? '환경 설정' : lang === 'en' ? 'Preferences' : lang === 'ja' ? '環境設定' : '偏好设置'}
        </div>
      </div>

      <Section label={t.languages}>
        <div style={{ background: EG.surfaceLow, borderRadius: 24, overflow: 'hidden' }}>
          {langs.map((l, i) => (
            <div key={l.code} onClick={() => setLang(l.code)}
              style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                padding: '16px 18px', borderTop: i ? `1px solid ${EG.surfaceCt}` : 'none',
                cursor: 'pointer', transition: 'background 0.15s',
                background: l.code === lang ? EG.primaryC : 'transparent' }}>
              <div>
                <div style={{ fontFamily: FONT_DISPLAY, fontSize: 16, fontWeight: 600,
                  letterSpacing: '-0.01em', color: l.code === lang ? EG.onPrimaryC : EG.ink }}>{l.label}</div>
                <div style={{ fontSize: 11, color: EG.outline, marginTop: 1, fontFamily: FONT_BODY }}>{l.sub}</div>
              </div>
              <div style={{ width: 22, height: 22, borderRadius: '50%',
                border: `1.5px solid ${l.code === lang ? EG.primary : EG.outlineV}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {l.code === lang && <div style={{ width: 10, height: 10, borderRadius: '50%', background: EG.primary }}/>}
              </div>
            </div>
          ))}
        </div>
      </Section>

      <Section label={t.userType}>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          {[
            { id: 'domestic', label: t.domestic, glyph: 'KR', sub: lang === 'ko' ? '한국어 우선' : 'KO first' },
            { id: 'foreign', label: t.foreign, glyph: 'EN', sub: lang === 'ko' ? '다국어 안내' : 'Multi-lang' },
          ].map(u => (
            <div key={u.id} onClick={() => setUserType(u.id)}
              style={{ padding: '18px 16px', borderRadius: 24, cursor: 'pointer',
                background: userType === u.id ? EG.primary : EG.surfaceLow,
                color: userType === u.id ? '#fff' : EG.ink,
                transition: 'background 0.18s' }}>
              <div style={{ width: 36, height: 36, borderRadius: '50%',
                background: userType === u.id ? 'rgba(255,255,255,0.18)' : EG.surfaceCt,
                display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                fontFamily: FONT_MONO, fontSize: 11, fontWeight: 700,
                color: userType === u.id ? '#fff' : EG.ink2 }}>{u.glyph}</div>
              <div style={{ marginTop: 12, fontFamily: FONT_DISPLAY, fontWeight: 600, fontSize: 16, letterSpacing: '-0.01em' }}>{u.label}</div>
              <div style={{ fontSize: 11, opacity: 0.75, marginTop: 2, fontFamily: FONT_BODY }}>{u.sub}</div>
            </div>
          ))}
        </div>
      </Section>

      <Section label={t.notify}>
        <div style={{ background: EG.surfaceLow, borderRadius: 24, overflow: 'hidden' }}>
          {[
            { label: lang === 'ko' ? '날씨 변화 알림' : lang === 'en' ? 'Weather alerts' : lang === 'ja' ? '天気変化' : '天气提醒', on: true },
            { label: lang === 'ko' ? '버스 도착 임박' : lang === 'en' ? 'Bus arrival' : lang === 'ja' ? 'バス到着' : '公交到达', on: true },
            { label: lang === 'ko' ? '여정 알림' : lang === 'en' ? 'Route reminders' : lang === 'ja' ? 'ルート通知' : '路线提醒', on: false },
          ].map((n, i) => (
            <div key={i} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              padding: '16px 18px', borderTop: i ? `1px solid ${EG.surfaceCt}` : 'none',
              fontFamily: FONT_BODY, fontSize: 14, color: EG.ink }}>
              <span>{n.label}</span>
              <Switch value={n.on}/>
            </div>
          ))}
        </div>
      </Section>

      <div style={{ height: 130 }}/>
    </div>
  );
};

const Section = ({ label, children }) => (
  <div style={{ padding: '0 24px 24px', fontFamily: FONT_BODY }}>
    <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.14em', color: EG.outline,
      textTransform: 'uppercase', marginBottom: 10 }}>{label}</div>
    {children}
  </div>
);

const Switch = ({ value }) => (
  <div style={{ width: 44, height: 26, borderRadius: 999, background: value ? EG.primary : EG.outlineV,
    position: 'relative', transition: 'background 0.2s' }}>
    <div style={{ position: 'absolute', top: 2, left: value ? 20 : 2,
      width: 22, height: 22, borderRadius: '50%', background: EG.surface,
      boxShadow: '0 1px 3px rgba(0,0,0,0.2)', transition: 'left 0.2s' }} />
  </div>
);

// ─────────────────────────────────────────────────────────────
// SPOT DETAIL — full-screen modal sliding up
// ─────────────────────────────────────────────────────────────
const SpotDetail = ({ spotId, lang, weather, route, addRoute, removeRoute, onClose }) => {
  const t = I18N[lang];
  const spot = SPOTS.find(s => s.id === spotId);
  if (!spot) return null;
  const inRoute = route.some(r => r.id === spot.id);

  return (
    <div style={{ position: 'absolute', inset: 0, background: EG.surface, zIndex: 60, overflowY: 'auto',
      animation: 'jfSlideUp 0.32s cubic-bezier(.2,.7,.3,1)' }}>
      <StatusBar/>
      {/* hero */}
      <div style={{ padding: '0 16px' }}>
        <SpotImg spot={spot} height={300} radius={32} />
        <button onClick={onClose} style={{
          position: 'absolute', top: 60, left: 30, width: 40, height: 40, borderRadius: '50%',
          background: 'rgba(252,249,242,0.92)', border: `1px solid ${EG.outlineV}`,
          backdropFilter: 'blur(10px)', cursor: 'pointer', fontSize: 18, color: EG.ink, fontWeight: 600,
          display: 'inline-flex', alignItems: 'center', justifyContent: 'center'
        }}>←</button>
      </div>

      <div style={{ padding: '20px 24px 0', fontFamily: FONT_BODY }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 8 }}>
          <Chip kind="primary">{t['kind' + spot.kind.charAt(0).toUpperCase() + spot.kind.slice(1)] || spot.kind}</Chip>
          <Chip kind="outline">{spot.region}</Chip>
        </div>
        <div style={{ fontFamily: FONT_DISPLAY, fontWeight: 700, fontSize: 32, letterSpacing: '-0.03em',
          color: EG.ink, lineHeight: 1.05 }}>{spot.name[lang]}</div>
        <div style={{ fontSize: 14, color: EG.ink2, marginTop: 6, lineHeight: 1.5 }}>{spot.blurb[lang]}</div>
      </div>

      {/* info grid */}
      <div style={{ padding: '20px 24px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <InfoTile label={t.nextBus} value={`${spot.busIn}m`} sub={t.busLine(spot.busLine)} tone="tertiary"/>
        <InfoTile label={t.walking} value={`${spot.walk}m`} sub={lang === 'ko' ? '정류장에서' : 'from stop'}/>
        <InfoTile label={t.timeline} value={spot.hours} sub={lang === 'ko' ? '운영시간' : 'open'}/>
        <InfoTile label={t.weather} value={WEATHERS[weather].temp + '°'} sub={WEATHERS[weather].label[lang]}/>
      </div>

      {/* mini map */}
      <div style={{ margin: '24px 24px 0', height: 180, borderRadius: 24, overflow: 'hidden',
        background: EG.surfaceLow, position: 'relative' }}>
        <JejuMap spots={[spot]} weather={weather} highlightId={spot.id} dim={1}/>
      </div>

      {/* CTA */}
      <div style={{ padding: '20px 24px 120px', display: 'flex', gap: 10 }}>
        <PillButton kind="ghost" size="lg" style={{ flex: '0 0 auto', width: 60 }}>♡</PillButton>
        <PillButton kind={inRoute ? 'inverse' : 'primary'} size="lg" style={{ flex: 1 }}
          onClick={() => inRoute ? removeRoute(spot.id) : addRoute(spot.id)}>
          {inRoute ? '✓  ' + t.added : '+  ' + t.addToRoute}
        </PillButton>
      </div>
    </div>
  );
};

const InfoTile = ({ label, value, sub, tone }) => {
  const accent = tone === 'tertiary' ? EG.tertiary : EG.ink;
  return (
    <div style={{ background: EG.surfaceLow, borderRadius: 18, padding: '14px 16px', fontFamily: FONT_BODY }}>
      <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.12em', color: EG.outline, textTransform: 'uppercase' }}>{label}</div>
      <div style={{ marginTop: 6, fontFamily: FONT_DISPLAY, fontWeight: 700, fontSize: 22, color: accent, letterSpacing: '-0.02em' }}>
        {value}
      </div>
      <div style={{ fontSize: 11, color: EG.ink2, marginTop: 2 }}>{sub}</div>
    </div>
  );
};

Object.assign(window, { ExploreScreen, RouteScreen, SettingsScreen, SpotDetail });
