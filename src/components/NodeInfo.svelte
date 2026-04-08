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
  import Tooltip from './Tooltip.svelte';

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
    <div class="card-header-left">
      <span class="card-title">Node Info</span>
      <Tooltip text="Basic information about this DEMOS node — its software version and the address other nodes use to connect to it." />
    </div>
  </div>

  <dl class="kv-list">
    <div class="kv-row">
      <dt class="kv-label">
        Version
        <Tooltip text="The software version number of the DEMOS node (e.g. 0.9.8). Newer versions may include bug fixes and new features." />
      </dt>
      <dd class="kv-value plain">{data.version ?? '—'}</dd>
    </div>
    <div class="kv-row">
      <dt class="kv-label">
        Version Name
        <Tooltip text="The human-readable codename for this software release (e.g. 'Oxlong Michael'). Different versions of the node software use different codenames." />
      </dt>
      <dd class="kv-value plain">{data.version_name ?? '—'}</dd>
    </div>
    <div class="kv-row">
      <dt class="kv-label">
        Connection
        <Tooltip text="The network address and port that other DEMOS nodes use to connect to this node. You can share this address with others to let them peer with you." />
      </dt>
      <dd class="kv-value">{data.connectionString ?? '—'}</dd>
    </div>
    <div class="kv-row">
      <dt class="kv-label">
        Identity
        <Tooltip text="A unique cryptographic fingerprint that permanently identifies this node on the network — like a passport number. Hover over the value to see the full ID." />
      </dt>
      <dd class="kv-value" title={data.identity}>{truncate(data.identity, 42)}</dd>
    </div>
  </dl>
</div>
