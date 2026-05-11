<script lang="ts">
    import { averages } from '$lib/functions/gradeAverages/averages';
    import { neoUniversisGet } from '$lib/dataService';
    import { shield, linkOutline, barbellOutline, addOutline, chevronForwardOutline, menuOutline, closeOutline, newspaperOutline } from 'ionicons/icons';
    import { register } from 'swiper/element/bundle';
    import { navController } from '$components/shared/StackedNav';
    import PersonalInfo from '$src/routes/personalInfo/personalInfo.svelte';
    import RecentItems from '$components/recentResults/recents.svelte';
    import HomepageSkeleton from '$lib/components/homepage/homepageSkeleton.svelte';
    import { goto } from '$app/navigation';
    import { getVocativeCase } from '$lib/globalFunctions/getVocativeCase';
    import { getLocale, t } from '$lib/i18n';
    import { EventStore } from '$lib/components/calendar/event/EventStore';
    import type { Event } from '$lib/components/calendar/event/Event';
    import Links from '$src/routes/quickLinks/quickLinks.svelte';
    import { fetchUniversisEvents } from '$lib/components/calendar/calendarUtils';
    import { registerPlugin, Capacitor } from '@capacitor/core';
    import { Browser } from '@capacitor/browser';
    import { locale } from '$lib/i18n';
    import { StatusBar, Style } from '@capacitor/status-bar';
    import authLogoWhite from '$lib/assets/auth-logo-white.png';

    const AppLauncherPlugin = registerPlugin('AppLauncherPlugin');
    register();

    let headerExpanded = false;

    $: upcomingEvents = $EventStore
        .filter((event: Event) => new Date(event.slot.start) >= new Date())
        .sort((a: Event, b: Event) => new Date(a.slot.start).getTime() - new Date(b.slot.start).getTime())
        .slice(0, 3);

    function formatEventDate(date: Date): string {
        const eventDate = new Date(date);
        const today = new Date();
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        if (eventDate.toDateString() === today.toDateString()) return $t('homepage.today');
        if (eventDate.toDateString() === tomorrow.toDateString()) return $t('homepage.tomorrow');
        return eventDate.toLocaleDateString(getLocale(), { month: 'short', day: 'numeric' });
    }

    function formatEventTime(date: Date): string {
        return new Date(date).toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
    }

    async function openGym() { await Browser.open({ url: 'https://gym.auth.gr/reservations/' }); }
    async function openAuthNews() { await Browser.open({ url: 'https://www.auth.gr' }); }

    async function handleCampusSafetyClick() {
        const packageName = 'gr.auth.android.incidentmanager';
        const isAndroid = Capacitor.getPlatform() === 'android';
        if (isAndroid) {
            try {
                const result = await AppLauncherPlugin.launchApp({ packageName });
                if (!result.launched) window.location.href = `market://details?id=${packageName}`;
            } catch { window.location.href = `market://details?id=${packageName}`; }
        } else { window.location.href = `https://play.google.com/store/apps/details?id=${packageName}&hl=el`; }
    }

    let givenName = '', numPassedSubjects = 0, numSubjects = 0, average = 0;
    let departmentName = '', studyLevel = '', actualSemester = 0, fullName = '';
    let showLogoAvatar = false;

    function toggleAvatar(e: MouseEvent) {
        e.stopPropagation();
        showLogoAvatar = !showLogoAvatar;
    }

    async function getInfo(loc: string) {
        if ($EventStore.length === 0) fetchUniversisEvents();
        let expandedLocale = loc === 'el' ? '' : '($expand=locale)';
        let personalData = await neoUniversisGet(
            `Students/me?$expand=studyProgram($expand=studyLevel${expandedLocale}), department${expandedLocale}${expandedLocale !== '' ? ', person' + expandedLocale : ''}`
        );
        fullName       = expandedLocale === '' ? personalData.person.name : personalData.person.locale.name;
        givenName      = expandedLocale === '' ? personalData.person.givenName : personalData.person.locale.givenName;
        departmentName = expandedLocale === '' ? personalData.department?.name : personalData.department?.locale.name;
        studyLevel     = expandedLocale === '' ? personalData.studyProgram?.studyLevel?.name : personalData.studyProgram?.studyLevel?.locale.name;
        actualSemester = personalData.actualSemester || null;
        let subjects = (await neoUniversisGet('students/me/courses?$top=-1')).value;
        numSubjects = subjects?.length;
        numPassedSubjects = subjects.filter((c: any) => c.isPassed == 1).length;
        averages().then((res) => { average = (res as any).weighted_avg; });
    }

    let isStatusBarHidden = false;
    async function handleScroll(event: CustomEvent) {
        const scrollTop = event.detail.scrollTop;
        if (scrollTop > 12 && !isStatusBarHidden) { await StatusBar.hide(); isStatusBarHidden = true; }
        else if (scrollTop <= 12 && isStatusBarHidden) { await StatusBar.show(); isStatusBarHidden = false; }
    }

    $: StatusBar.setStyle({ style: Style.Dark });

    $: initials = (() => {
        const parts = fullName.split(' ').filter(Boolean);
        if (parts.length === 0) return '';
        return (parts.length === 1 ? parts[0][0] : parts[parts.length - 1][0] + parts[0][0]).toUpperCase();
    })();
</script>

<ion-page>
    <ion-content id="homepage_content" fullscreen={false} scrollEvents={true} on:ionScroll={handleScroll}>
        {#await getInfo($locale)}
            <HomepageSkeleton />
        {:then}
            <div id="scrolled_content">

                <!-- ── HERO HEADER ──────────────────────────────── -->
                <div class="hero-band">
                    <div class="hero-top">

                        <div
                            class="avatar-group ion-activatable"
                            on:click={() => navController.push(PersonalInfo)}
                            aria-hidden="true"
                        >
                            <ion-ripple-effect />
                            <div class="avatar-flip" on:click={toggleAvatar} aria-hidden="true">
                                <div class="avatar-inner" class:flipped={showLogoAvatar}>
                                    <div class="avatar-face avatar-front">{initials}</div>
                                    <div class="avatar-face avatar-back">
                                        <img src={authLogoWhite} alt="AUTH Logo" />
                                    </div>
                                </div>
                            </div>
                            <div class="greet-col">
                                <span class="greet-sub">{$t('homepage.greeting')}</span>
                                <span class="greet-name">{getVocativeCase(givenName)}!</span>
                            </div>
                        </div>

                        <div
                            class="menu-btn ion-activatable"
                            on:click={() => headerExpanded = !headerExpanded}
                            aria-hidden="true"
                        >
                            <ion-ripple-effect />
                            <ion-icon icon={headerExpanded ? closeOutline : menuOutline} />
                        </div>

                    </div>

                    <!-- Collapsible personal info -->
                    <div class="personal-panel" class:open={headerExpanded}>
                        <div class="panel-divider" />
                        <div class="id-main">{fullName}</div>
                        <div class="id-pills">
                            {#if departmentName}<span class="id-pill">{departmentName}</span>{/if}
                            {#if studyLevel}<span class="id-pill">{studyLevel}</span>{/if}
                            {#if actualSemester}<span class="id-pill">{actualSemester}{$t('homepage.semesterSuffix')}</span>{/if}
                        </div>
                    </div>
                </div>

                <!-- ── STATS BAR ────────────────────────────────── -->
                <div class="section-wrap">
                    <div class="stats-bar">
                        <div class="stat">
                            <span class="stat-val">{average ? average.toFixed(1) : '—'}</span>
                            <span class="stat-lbl">{$t('homepage.average')}</span>
                        </div>
                        <div class="stat-sep" />
                        <div class="stat">
                            <span class="stat-val">{numPassedSubjects}</span>
                            <span class="stat-lbl">{$t('homepage.passed')}</span>
                        </div>
                        <div class="stat-sep" />
                        <div class="stat">
                            <span class="stat-val">{numSubjects}</span>
                            <span class="stat-lbl">{$t('homepage.total')}</span>
                        </div>
                    </div>
                </div>

                <!-- ── SERVICE TILES ────────────────────────────── -->
                <div class="section-wrap">
                    <div class="masonry-grid">

                        <div
                            class="m-tile tile-tall tile-links ion-activatable"
                            on:click={() => navController.push(Links)}
                            aria-hidden="true"
                        >
                            <ion-ripple-effect />
                            <ion-icon icon={linkOutline} class="tile-icon" />
                            <span class="tile-label">{$t('homepage.quickLinks')}</span>
                            <span class="tile-sub">{$t('homepage.quickLinksSub')}</span>
                        </div>

                        <div
                            class="m-tile tile-safety ion-activatable"
                            on:click={handleCampusSafetyClick}
                            aria-hidden="true"
                        >
                            <ion-ripple-effect />
                            <ion-icon icon={shield} class="tile-icon" />
                            <span class="tile-label">{$t('homepage.campusSafety')}</span>
                        </div>

                        <div
                            class="m-tile tile-gym ion-activatable"
                            on:click={openGym}
                            aria-hidden="true"
                        >
                            <ion-ripple-effect />
                            <ion-icon icon={barbellOutline} class="tile-icon" />
                            <span class="tile-label">{$t('homepage.gym')}</span>
                        </div>

                        <div
                            class="m-tile tile-wide tile-news ion-activatable"
                            on:click={openAuthNews}
                            aria-hidden="true"
                        >
                            <ion-ripple-effect />
                            <ion-icon icon={newspaperOutline} class="tile-icon" />
                            <span class="tile-label">{$t('homepage.news')}</span>
                            <span class="tile-sub">auth.gr</span>
                        </div>

                    </div>
                </div>

                <!-- ── UPCOMING EVENTS ──────────────────────────── -->
                <div class="section-wrap">
                    <div class="section-header">
                        <h4 class="section-title">{$t('homepage.dontForget')}</h4>
                        <button class="section-link" on:click={() => goto('/pages/calendar')}>
                            {$t('homepage.viewCalendar')}
                            <ion-icon icon={chevronForwardOutline} class="link-chevron" />
                        </button>
                    </div>

                    <div class="chips-list">
                        {#if upcomingEvents.length > 0}
                            {#each upcomingEvents as event}
                                <div
                                    class="event-chip ion-activatable"
                                    aria-hidden="true"
                                    on:click={() => goto(`/pages/calendar?showEventId=${encodeURIComponent(event.id)}&eventDate=${encodeURIComponent(new Date(event.slot.start).toISOString())}`)}
                                >
                                    <ion-ripple-effect />
                                    <div class="chip-date-badge">
                                        <span class="chip-date-day">{formatEventDate(event.slot.start)}</span>
                                        <span class="chip-date-time">{formatEventTime(event.slot.start)}</span>
                                    </div>
                                    <div class="chip-body">
                                        <span class="chip-title">{event.title}</span>
                                        <span class="event-type-badge" data-type={event.type}>{event.type}</span>
                                    </div>
                                    <ion-icon icon={chevronForwardOutline} class="chip-chevron" />
                                </div>
                            {/each}
                        {:else}
                            <div
                                class="event-chip chip-empty ion-activatable"
                                on:click={() => goto('/pages/calendar')}
                                aria-hidden="true"
                            >
                                <ion-ripple-effect />
                                <div class="chip-date-badge chip-date-badge--empty">
                                    <ion-icon icon={addOutline} class="chip-add-icon" />
                                </div>
                                <div class="chip-body">
                                    <span class="chip-title chip-title--muted">{$t('homepage.noEvents')}</span>
                                    <span class="chip-sub">{$t('homepage.createNew')}</span>
                                </div>
                                <ion-icon icon={chevronForwardOutline} class="chip-chevron" />
                            </div>
                        {/if}
                    </div>
                </div>

                <!-- ── RECENT ITEMS ─────────────────────────────── -->
                <div class="section-wrap section-wrap--last">
                    <div class="section-header">
                        <h4 class="section-title">{$t('homepage.updates')}</h4>
                    </div>
                    <RecentItems maxCards={6} />
                </div>

            </div>
        {/await}
    </ion-content>
</ion-page>

<style>
    :global(ion-tabs):has(#homepage_content) :global(ion-toolbar) {
        padding-top: var(--ion-safe-area-top) !important;
    }
    :global(ion-tabs):has(#homepage_content) {
        padding-top: 0 !important;
    }

    #scrolled_content {
        display: flex;
        flex-direction: column;
        padding-bottom: 2rem;
    }

    /* ── HERO BAND ───────────────────────────────────────────── */
    .hero-band {
        background: #611414;
        border-bottom-left-radius: 1.25rem;
        border-bottom-right-radius: 1.25rem;
        position: sticky; 
        top: 0; 
        z-index: 100;
        overflow: hidden;
    }

    .hero-top {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 0.5rem 1rem 0.75rem;
    }

    .avatar-group {
        display: flex;
        align-items: center;
        gap: 0.6rem;
        border-radius: 50px;
        padding: 0.2rem 0.5rem 0.2rem 0.2rem;
        position: relative;
        overflow: hidden;
        cursor: pointer;
    }

    .greet-col {
        display: flex;
        flex-direction: column;
        line-height: 1.2;
    }
    .greet-sub {
        font-size: 0.68rem;
        color: rgba(255, 255, 255, 0.6);
    }
    .greet-name {
        font-size: 1rem;
        font-weight: 700;
        color: white;
    }

    .menu-btn {
        width: 2.25rem;
        height: 2.25rem;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        color: white;
        font-size: 1.35rem;
        cursor: pointer;
        position: relative;
        overflow: hidden;
        flex-shrink: 0;
    }

    /* Collapsible panel */
    .personal-panel {
        overflow: hidden;
        max-height: 0;
        opacity: 0;
        padding: 0 1rem;
        transition:
            max-height 0.38s cubic-bezier(0.4, 0, 0.2, 1),
            opacity 0.28s ease,
            padding 0.3s ease;
    }
    .personal-panel.open {
        max-height: 120px;
        opacity: 1;
        padding: 0 1rem 1rem;
    }

    .panel-divider {
        height: 1px;
        background: rgba(255, 255, 255, 0.15);
        margin-bottom: 0.75rem;
    }

    .id-main {
        color: white;
        font-size: 1rem;
        font-weight: 700;
        margin-bottom: 0.4rem;
        line-height: 1.2;
    }

    .id-pills {
        display: flex;
        flex-wrap: wrap;
        gap: 0.3rem;
    }
    .id-pill {
        background: rgba(255, 255, 255, 0.14);
        color: rgba(255, 255, 255, 0.88);
        font-size: 0.68rem;
        font-weight: 500;
        padding: 0.2rem 0.55rem;
        border-radius: 50px;
    }

    /* Avatar flip */
    .avatar-flip {
        width: 2.4rem;
        height: 2.4rem;
        perspective: 1000px;
        flex-shrink: 0;
        cursor: pointer;
    }
    .avatar-inner {
        width: 100%;
        height: 100%;
        position: relative;
        transform-style: preserve-3d;
        transition: transform 0.6s cubic-bezier(0.4, 0, 0.2, 1);
    }
    .avatar-inner.flipped { transform: rotateY(180deg); }
    .avatar-face {
        position: absolute;
        inset: 0;
        border-radius: 50%;
        backface-visibility: hidden;
        display: flex;
        align-items: center;
        justify-content: center;
        overflow: hidden;
    }
    .avatar-front {
        background: transparent;
        border: 1.5px solid rgba(255, 255, 255, 0.6);
        color: white;
        font-weight: 700;
        font-size: 0.85rem;
        box-sizing: border-box;
    }
    .avatar-back {
        transform: rotateY(180deg);
        border: 1.5px solid rgba(255, 255, 255, 0.6);
    }
    .avatar-back img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        display: block;
    }

    /* ── STATS BAR ───────────────────────────────────────────── */
    .stats-bar {
        display: flex;
        align-items: center;
        background: var(--app-color-map-input, #fff);
        border-radius: 1rem;
        border: 1px solid var(--ion-color-light-shade);
        padding: 0.75rem 0;
    }

    .stat {
        flex: 1;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.1rem;
    }
    .stat-val {
        font-size: 1.25rem;
        font-weight: 700;
        color: #611414;
        line-height: 1;
    }
    .stat-lbl {
        font-size: 0.6rem;
        color: var(--ion-color-medium);
        text-transform: uppercase;
        letter-spacing: 0.05em;
    }
    .stat-sep {
        width: 1px;
        height: 1.75rem;
        background: var(--ion-color-light-shade);
    }

    /* ── SECTION SCAFFOLDING ─────────────────────────────────── */
    .section-wrap {
        padding: 1rem 1rem 0;
    }
    .section-wrap--last {
        padding-bottom: 0.5rem;
    }
    .section-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 0.6rem;
    }
    .section-title {
        font-size: 0.95rem;
        font-weight: 700;
        margin: 0;
    }
    .section-link {
        display: flex;
        align-items: center;
        gap: 0.1rem;
        font-size: 0.72rem;
        font-weight: 600;
        color: #611414;
        background: none;
        border: none;
        padding: 0;
        cursor: pointer;
    }
    .link-chevron { font-size: 0.72rem; }

    /* ── MASONRY TILES ───────────────────────────────────────── */
    .masonry-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 0.55rem;
    }

    .m-tile {
        border-radius: 1rem;
        padding: 0.875rem;
        display: flex;
        flex-direction: column;
        justify-content: flex-end;
        cursor: pointer;
        position: relative;
        overflow: hidden;
        min-height: 88px;
    }
    .tile-tall {
        grid-row: span 2;
        min-height: 184px;
    }
    .tile-wide {
        grid-column: span 2;
        flex-direction: row;
        align-items: center;
        gap: 0.75rem;
        min-height: 56px;
        padding: 0.7rem 1rem;
    }
    .tile-wide .tile-icon { font-size: 1.3rem; margin-bottom: 0; }
    .tile-wide .tile-label { font-size: 0.875rem; }
    .tile-wide .tile-sub { margin-top: 0; flex: 1; }

    .tile-icon {
        font-size: 1.5rem;
        color: white;
        margin-bottom: 0.35rem;
    }
    .tile-label {
        color: white;
        font-size: 0.8rem;
        font-weight: 700;
        line-height: 1.2;
    }
    .tile-sub {
        color: rgba(255, 255, 255, 0.65);
        font-size: 0.68rem;
        margin-top: 0.2rem;
        line-height: 1.3;
    }

    .tile-links  { background: #1d4e89; }
    .tile-safety { background: #2d6a4f; }
    .tile-gym    { background: #7b3f00; }
    .tile-news   { background: #4a235a; }

    /* ── EVENT CHIPS ─────────────────────────────────────────── */
    .chips-list {
        display: flex;
        flex-direction: column;
        gap: 0.45rem;
    }

    .event-chip {
        display: flex;
        align-items: center;
        gap: 0.7rem;
        background: var(--app-color-map-input, #fff);
        border-radius: 0.875rem;
        padding: 0.65rem 0.75rem;
        border: 1px solid var(--ion-color-light-shade);
        position: relative;
        overflow: hidden;
        cursor: pointer;
    }

    .chip-date-badge {
        display: flex;
        flex-direction: column;
        align-items: center;
        background: #fdf0f0;
        border-radius: 0.5rem;
        padding: 0.28rem 0.45rem;
        min-width: 2.5rem;
        flex-shrink: 0;
    }
    .chip-date-badge--empty { background: var(--ion-color-light); }

    .chip-date-day {
        font-size: 0.6rem;
        font-weight: 700;
        color: #611414;
        line-height: 1.15;
        text-transform: uppercase;
    }
    .chip-date-time {
        font-size: 0.6rem;
        color: #8b2020;
        line-height: 1.15;
    }
    .chip-add-icon {
        font-size: 1rem;
        color: var(--ion-color-medium);
    }

    .chip-body {
        flex: 1;
        min-width: 0;
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
    }
    .chip-title {
        font-size: 0.85rem;
        font-weight: 600;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }
    .chip-title--muted { opacity: 0.55; }
    .chip-sub {
        font-size: 0.72rem;
        color: var(--ion-color-medium);
    }
    .chip-chevron {
        font-size: 0.85rem;
        color: var(--ion-color-medium);
        flex-shrink: 0;
    }

    .event-type-badge {
        font-size: 0.58rem;
        font-weight: 700;
        padding: 0.15rem 0.4rem;
        border-radius: 0.3rem;
        align-self: flex-start;
        background: var(--ion-color-light-shade);
    }
    .event-type-badge[data-type="TEST"]       { background: #ff6b6b; color: white; }
    .event-type-badge[data-type="ASSIGNMENT"] { background: #ffa726; color: white; }
    .event-type-badge[data-type="CLASS"]      { background: #66bb6a; color: white; }
    .event-type-badge[data-type="TASK"]       { background: #42a5f5; color: white; }
</style>