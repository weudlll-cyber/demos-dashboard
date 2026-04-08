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
  import Tooltip from './Tooltip.svelte';

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
    <div class="card-header-left">
      <span class="card-title">Sync Status</span>
      <Tooltip text="Shows how in sync this node is with the rest of the DEMOS network. All nodes on the network should share the same block height and block hash." />
    </div>
    {#if peer}
      <span
        class="pill {syncOk ? 'ok' : 'err'}"
        title={syncOk
          ? 'This node is fully up to date with the network.'
          : 'This node is behind the network. It may still be catching up.'}
      >{syncOk ? 'In Sync' : 'Not Synced'}</span>
    {/if}
  </div>

  {#if !peer}
    <p style="color: var(--text-muted); font-size: 0.85rem;">No peer data available.</p>
  {:else}
    <dl class="kv-list">
      <div class="kv-row">
        <dt class="kv-label">
          Block Height
          <Tooltip text="The number of the latest block this node has processed. A higher number means the node is more up to date. All synced nodes on the network share the same block height." />
        </dt>
        <dd class="kv-value plain">{sync?.block?.toLocaleString() ?? '—'}</dd>
      </div>
      <div class="kv-row">
        <dt class="kv-label">
          Block Hash
          <Tooltip text="The cryptographic fingerprint of the latest block. Every node that is fully synced with the network shows the exact same hash. If this differs, the node may be on a fork or still catching up." />
        </dt>
        <dd class="kv-value" title={sync?.block_hash}>{sync?.block_hash ?? '—'}</dd>
      </div>
      <div class="kv-row">
        <dt class="kv-label">
          Online
          <Tooltip text="Whether this node is currently reachable on the network and accepting connections from other peers." />
        </dt>
        <dd class="kv-value plain">
          <span class="pill {online ? 'ok' : 'err'}">{online ? 'Yes' : 'No'}</span>
        </dd>
      </div>
      <div class="kv-row">
        <dt class="kv-label">
          Ready
          <Tooltip text="Whether this node has finished starting up and is ready to process new blocks and transactions. A node can be online but not yet ready if it is still initializing." />
        </dt>
        <dd class="kv-value plain">
          <span class="pill {ready ? 'ok' : 'warn'}">{ready ? 'Yes' : 'No'}</span>
        </dd>
      </div>
      <div class="kv-row">
        <dt class="kv-label">
          Verified
          <Tooltip text="Whether this node's blockchain data has passed cryptographic verification checks. An unverified node may still be checking the integrity of its chain." />
        </dt>
        <dd class="kv-value plain">
          <span class="pill {verified ? 'ok' : 'warn'}">{verified ? 'Yes' : 'No'}</span>
        </dd>
      </div>
    </dl>
  {/if}
</div>
