<!--
  @file SyncStatus.svelte
  @project DEMOS Node Dashboard
  @repository https://github.com/weudlll-cyber/demos-dashboard

  @description
    Displays the synchronisation state of the first peer in the peerlist.
    Svelte reactive declarations ($:) keep all derived booleans in sync
    whenever the `peer` prop changes (i.e. on every poll cycle).

    Status pills use three visual states:
      ok   (green) — condition is true and healthy
      warn (amber) — condition is false but not critical (e.g. not ready yet)
      err  (red)   — condition indicates a real problem (e.g. offline, out of sync)

  @props
    peer {object|undefined}  First element of peerlist from the node response.
                             Treated as optional; renders placeholder if undefined.

  @author  weudlll-cyber
  @license MIT
-->
<script>
  // peer is the first entry from peerlist, or undefined
  export let peer = undefined;

  $: sync = peer?.sync;
  $: status = peer?.status;
  $: verification = peer?.verification;

  $: syncOk  = sync?.status === true;
  $: online  = status?.online === true;
  $: ready   = status?.ready === true;
  $: verified = verification?.status === true;
</script>

<div class="card">
  <div class="card-header">
    <span class="card-title">Sync Status</span>
    {#if peer}
      <span class="pill {syncOk ? 'ok' : 'err'}">{syncOk ? 'In Sync' : 'Not Synced'}</span>
    {/if}
  </div>

  {#if !peer}
    <p style="color: var(--text-muted); font-size: 0.85rem;">No peer data available.</p>
  {:else}
    <dl class="kv-list">
      <div class="kv-row">
        <dt class="kv-label">Block Height</dt>
        <dd class="kv-value plain">{sync?.block?.toLocaleString() ?? '—'}</dd>
      </div>
      <div class="kv-row">
        <dt class="kv-label">Block Hash</dt>
        <dd class="kv-value" title={sync?.block_hash}>{sync?.block_hash ?? '—'}</dd>
      </div>
      <div class="kv-row">
        <dt class="kv-label">Online</dt>
        <dd class="kv-value plain">
          <span class="pill {online ? 'ok' : 'err'}">{online ? 'Yes' : 'No'}</span>
        </dd>
      </div>
      <div class="kv-row">
        <dt class="kv-label">Ready</dt>
        <dd class="kv-value plain">
          <span class="pill {ready ? 'ok' : 'warn'}">{ready ? 'Yes' : 'No'}</span>
        </dd>
      </div>
      <div class="kv-row">
        <dt class="kv-label">Verified</dt>
        <dd class="kv-value plain">
          <span class="pill {verified ? 'ok' : 'warn'}">{verified ? 'Yes' : 'No'}</span>
        </dd>
      </div>
    </dl>
  {/if}
</div>
