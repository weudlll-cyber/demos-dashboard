<!--
  @file NodeInfo.svelte
  @project DEMOS Node Dashboard
  @repository https://github.com/weudlll-cyber/demos-dashboard

  @description
    Displays high-level metadata about the DEMOS node in a card.
    Shows: version, version name, connection string, and identity hash.
    The identity is truncated to 42 characters for readability; the full
    value is always accessible via the HTML title attribute (tooltip).

  @props
    data {object}  Full node response object from fetchNodeData().
                   Expected fields: version, version_name, connectionString, identity.
                   Missing fields render as '\u2014'.

  @author  weudlll-cyber
  @license MIT
-->
<script>
  export let data;

  // Limits long hex strings (e.g. identity) to `len` chars + ellipsis.
  // The full string is preserved in the HTML title attribute for copy-paste.
  function truncate(str, len = 24) {
    if (!str) return '—';
    return str.length > len ? str.slice(0, len) + '…' : str;
  }
</script>

<div class="card">
  <div class="card-header">
    <span class="card-title">Node Info</span>
  </div>

  <dl class="kv-list">
    <div class="kv-row">
      <dt class="kv-label">Version</dt>
      <dd class="kv-value plain">{data.version ?? '—'}</dd>
    </div>
    <div class="kv-row">
      <dt class="kv-label">Version Name</dt>
      <dd class="kv-value plain">{data.version_name ?? '—'}</dd>
    </div>
    <div class="kv-row">
      <dt class="kv-label">Connection</dt>
      <dd class="kv-value">{data.connectionString ?? '—'}</dd>
    </div>
    <div class="kv-row">
      <dt class="kv-label">Identity</dt>
      <dd class="kv-value" title={data.identity}>{truncate(data.identity, 42)}</dd>
    </div>
  </dl>
</div>
