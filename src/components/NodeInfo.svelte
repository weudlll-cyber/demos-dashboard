<script>
  export let data;

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
