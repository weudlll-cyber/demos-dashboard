<!--
  @file PeerList.svelte
  @project DEMOS Node Dashboard
  @repository https://github.com/weudlll-cyber/demos-dashboard

  @description
    Renders a full-width scrollable table listing every peer returned by the
    DEMOS node API. Each row shows all available status fields for that peer.

    Identity values are shortened with shortId() for display; the complete
    identity is accessible as an HTML title tooltip.

    The table wrapper has overflow-x:auto so the layout stays intact on
    narrow screens without horizontal page overflow.

  @props
    peers {Array}  The peerlist array from the node response.
                  Defaults to [] so the empty-state message renders safely
                  before any data arrives.

  @author  weudlll-cyber
  @license MIT
-->
<script>
  export let peers = [];

  // Shortens a peer identity hex string to 'first10…10…last6' for table display.
  // Full value is kept in the HTML title attribute for hover/copy access.
  function shortId(id) {
    if (!id) return '—';
    // Show first 10 and last 6 chars for readability
    return id.length > 20 ? id.slice(0, 10) + '…' + id.slice(-6) : id;
  }
</script>

<div class="card">
  <div class="card-header">
    <span class="card-title">Peer List</span>
    <span class="peer-count">{peers?.length ?? 0} peer{(peers?.length ?? 0) !== 1 ? 's' : ''}</span>
  </div>

  {#if !peers || peers.length === 0}
    <p style="color: var(--text-muted); font-size: 0.85rem;">No peers connected.</p>
  {:else}
    <div style="overflow-x: auto;">
      <table class="peer-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Identity</th>
            <th>Connection</th>
            <th>Online</th>
            <th>Ready</th>
            <th>Synced</th>
            <th>Block</th>
            <th>Verified</th>
          </tr>
        </thead>
        <tbody>
          {#each peers as peer, i}
            <tr>
              <td>{i + 1}</td>
              <td class="mono" title={peer.identity}>{shortId(peer.identity)}</td>
              <td class="mono">{peer.connection?.string ?? '—'}</td>
              <td>
                <span class="pill {peer.status?.online ? 'ok' : 'err'}">
                  {peer.status?.online ? 'Yes' : 'No'}
                </span>
              </td>
              <td>
                <span class="pill {peer.status?.ready ? 'ok' : 'warn'}">
                  {peer.status?.ready ? 'Yes' : 'No'}
                </span>
              </td>
              <td>
                <span class="pill {peer.sync?.status ? 'ok' : 'err'}">
                  {peer.sync?.status ? 'Yes' : 'No'}
                </span>
              </td>
              <td>{peer.sync?.block?.toLocaleString() ?? '—'}</td>
              <td>
                <span class="pill {peer.verification?.status ? 'ok' : 'warn'}">
                  {peer.verification?.status ? 'Yes' : 'No'}
                </span>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</div>
