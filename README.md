# GloBlocks

A neon arcade brick-breaker built in Godot 4, styled as a sibling to LumaRush.

## GloBlocks Tuning

Primary gameplay knobs live in `resources/glo_blocks/config/GameplayConfig.tres`:

- `base_ball_speed`, `max_speed_cap`
- `speed_increase_interval_seconds`, `speed_increase_percent`
- `paddle_width`, `paddle_height`, `paddle_y_offset`, `paddle_smoothing`
- `min_reflection_angle_degrees`, `paddle_bounce_range_degrees`
- `rows`, `cols`, `block_size`, `spacing`, `grid_origin`
- `durability_tiers`, `durability_colors`, `durability_base_points`
- `combo_reset_on_paddle_hit`, `combo_multiplier_curve`, `combo_cap`
- `hit_freeze_duration`, `hit_freeze_time_scale`
- `screen_shake_strength`, `screen_shake_duration`
- `playfield_margin_x`, `playfield_top`, `playfield_bottom_margin`
- `playfield_min_width`, `playfield_min_height`
- `playfield_layout_mode`, `layout_reference_size`
- `side_hud_trigger_aspect`, `side_hud_width`, `side_hud_width_ratio`
- `side_hud_left_margin`, `side_hud_top_margin`
- `paddle_bottom_padding_ratio`, `paddle_bottom_padding_min`
- `physics_substep_radius_factor`, `physics_max_substeps`
- `collision_push_out_min`, `speed_interval_min_seconds`
- `playfield_glow_padding`, `playfield_frame_padding`, `combo_glow_padding`, `combo_glow_max_alpha`
- `high_score_save_key`

Layout strategy helpers are implemented in `scripts/glo_blocks/layout/PlayLayoutSystem.gd` and are designed to be portable to ArcadeCore:

- `SQUARE_CENTERED`: centered square play area that feels consistent in portrait and landscape.
- `ROTATE_TO_LANDSCAPE`: rotates gameplay 90 degrees in wide viewports (Starfall-style).

Pattern knobs live in `resources/glo_blocks/config/PatternConfig.tres`:

- `tier_distribution` (tier -> probability)
- `symmetrical`

Monetization knobs live in `resources/glo_blocks/config/MonetizationConfig.tres`:

- `ad_enabled`
- `interstitial_every_n_runs`
- `rewarded_continue_limit_per_run`
- `rewarded_score_multiplier`
- `local_override_path`

### Local Ad Unit IDs (Do Not Commit)

Create `configs/ads/AdUnits.local.json` (ignored by `.gitignore`) using `configs/ads/AdUnits.local.example.json` as a template.

Put your local app/interstitial/rewarded IDs there for development devices.

## CI and Deployment

The repository includes two GitHub Actions workflows:

- `.github/workflows/ci.yml`: runs `gdUnit4` tests on push and pull request.
- `.github/workflows/pages.yml`: exports the game for Web and deploys to GitHub Pages on push to `main` or `master`.

### GdUnit4 Tests

Tests live under `tests/` and are executed in CI via `godot-gdunit-labs/gdUnit4-action`.

### GitHub Pages

Web export uses `export_presets.cfg` preset `"Web"` and uploads `build/web` as the Pages artifact.
