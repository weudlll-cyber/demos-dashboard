<!--
  @file Tooltip.svelte
  @project DEMOS Node Dashboard
  @repository https://github.com/weudlll-cyber/demos-dashboard

  @description
    Reusable tooltip component. Renders a small circular '?' icon that shows
    an explanatory popup on hover (desktop), focus (keyboard), and tap (mobile).

    The popup uses position:fixed so it works correctly inside overflow:auto
    containers such as the scrollable peer table.

  @props
    text {string}  The tooltip text to display.

  @author  weudlll-cyber
  @license MIT
-->
<script>
  export let text = '';

  let show = false;
  let anchor;
  let tx = 0;
  let ty = 0;

  function open(e) {
    const el = anchor || e.currentTarget;
    const r = el.getBoundingClientRect();
    // Center horizontally on the icon; position above it with an 8px gap.
    tx = Math.round(r.left + r.width / 2);
    ty = Math.round(r.top - 8);
    show = true;
  }

  function close() {
    show = false;
  }

  function toggle(e) {
    if (show) {
      close();
    } else {
      open(e);
    }
  }
</script>

<span class="tooltip-wrap">
  <span
    bind:this={anchor}
    class="tooltip-icon"
    tabindex="0"
    role="button"
    aria-label="More information"
    aria-expanded={show}
    on:mouseenter={open}
    on:mouseleave={close}
    on:focus={open}
    on:blur={close}
    on:click={toggle}
    on:keydown={(e) => (e.key === 'Enter' || e.key === ' ') && (e.preventDefault(), toggle(e))}
  >?</span>

  {#if show}
    <span
      class="tooltip-box"
      role="tooltip"
      style="left:{tx}px; top:{ty}px"
    >{text}<span class="tooltip-arrow"></span></span>
  {/if}
</span>
