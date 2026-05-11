<script lang="ts">
    import { t } from '$lib/i18n';
    import { navController } from '$components/shared/StackedNav';
    import { schoolOutline, notificationsOutline, chevronForwardOutline } from 'ionicons/icons';

    export let recentItems: any[] = [];
    export let maxCards: number = 6;

    $: displayItems = recentItems.slice(0, maxCards);

    // ── helpers ────────────────────────────────────────────────

    function getGradeColor(grade: number): string {
        if (grade >= 8.5) return '#2d6a4f';
        if (grade >= 6)   return '#7b3f00';
        return '#611414';
    }

    function getGradeSwatchBg(grade: number): string {
        if (grade >= 8.5) return '#e8f5ee';
        if (grade >= 6)   return '#fdf3e7';
        return '#fdf0f0';
    }

    function getGradeSwatchColor(grade: number): string {
        if (grade >= 8.5) return '#2d6a4f';
        if (grade >= 6)   return '#7b3f00';
        return '#611414';
    }

    function formatRelativeTime(dateStr: string): string {
        if (!dateStr) return '';
        const date = new Date(dateStr);
        const now = new Date();
        const diffMs = now.getTime() - date.getTime();
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMins / 60);
        const diffDays = Math.floor(diffHours / 24);
        if (diffMins < 60)  return `${diffMins}' ago`;
        if (diffHours < 24) return `${diffHours}h ago`;
        if (diffDays === 1) return 'yesterday';
        if (diffDays < 7)   return `${diffDays}d ago`;
        return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
    }

    function getCourseName(item: any): string {
        return item.content?.courseExam?.course?.name
            || item.content?.courseExam?.course?.locale?.name
            || item.content?.name
            || '—';
    }

    function getGradeValue(item: any): number | null {
        const g = item.content?.grade ?? item.content?.courseExam?.grade;
        return g != null ? parseFloat(g) : null;
    }

    function getNotificationTitle(item: any): string {
        return item.content?.title || item.content?.subject || item.content?.name || '—';
    }

    function getNotificationDate(item: any): string {
        return item.content?.date || item.content?.createdAt || item.content?.timestamp || '';
    }

    function getGradeDate(item: any): string {
        return item.content?.courseExam?.examDate || item.content?.date || '';
    }
</script>

<div class="news-feed">
    {#if displayItems.length === 0}
        <div class="empty-state">
            <ion-icon icon={notificationsOutline} class="empty-icon" />
            <span class="empty-text">{$t('homepage.noUpdates')}</span>
        </div>
    {:else}
        {#each displayItems as item (item.id)}
            {#if item.type === 'recentGrade'}
                {@const grade = getGradeValue(item)}
                {@const barColor = getGradeColor(grade ?? 0)}
                {@const swatchBg = getGradeSwatchBg(grade ?? 0)}
                {@const swatchColor = getGradeSwatchColor(grade ?? 0)}
                <div class="news-card">
                    <div class="news-bar" style="background: {barColor};" />
                    <div class="news-body">
                        <div class="news-tag">{'homepage.recentGrade'}</div>
                        <div class="news-title">{getCourseName(item)}</div>
                        <div class="news-time">{formatRelativeTime(getGradeDate(item))}</div>
                    </div>
                    <div class="news-swatch" style="background: {swatchBg};">
                        {#if grade !== null}
                            <span class="grade-val" style="color: {swatchColor};">{grade % 1 === 0 ? grade : grade.toFixed(1)}</span>
                        {:else}
                            <ion-icon icon={schoolOutline} style="color: {swatchColor}; font-size: 1.2rem;" />
                        {/if}
                    </div>
                </div>
            {:else if item.type === 'notification'}
                <div class="news-card">
                    <div class="news-bar" style="background: #1d4e89;" />
                    <div class="news-body">
                        <div class="news-tag">{$t('homepage.notification')}</div>
                        <div class="news-title">{getNotificationTitle(item)}</div>
                        <div class="news-time">{formatRelativeTime(getNotificationDate(item))}</div>
                    </div>
                    <div class="news-swatch" style="background: #e8f0f8;">
                        <ion-icon icon={notificationsOutline} style="color: #1d4e89; font-size: 1.2rem;" />
                    </div>
                </div>
            {/if}
        {/each}
    {/if}
</div>

<style>
    .news-feed {
        display: flex;
        flex-direction: column;
        gap: 0.45rem;
    }

    .news-card {
        display: flex;
        align-items: stretch;
        background: var(--app-color-map-input, #fff);
        border-radius: 0.875rem;
        border: 1px solid var(--ion-color-light-shade);
        overflow: hidden;
        cursor: pointer;
    }

    .news-bar {
        width: 4px;
        flex-shrink: 0;
    }

    .news-body {
        flex: 1;
        min-width: 0;
        padding: 0.65rem 0.75rem;
        display: flex;
        flex-direction: column;
        gap: 0.15rem;
    }

    .news-tag {
        font-size: 0.6rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: var(--ion-color-medium);
    }

    .news-title {
        font-size: 0.85rem;
        font-weight: 600;
        line-height: 1.35;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .news-time {
        font-size: 0.7rem;
        color: var(--ion-color-medium);
    }

    .news-swatch {
        width: 3.25rem;
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .grade-val {
        font-size: 1.1rem;
        font-weight: 800;
        line-height: 1;
    }

    .empty-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.5rem;
        padding: 2rem 0;
        opacity: 0.45;
    }

    .empty-icon {
        font-size: 1.75rem;
        color: var(--ion-color-medium);
    }

    .empty-text {
        font-size: 0.85rem;
        color: var(--ion-color-medium);
    }
</style>