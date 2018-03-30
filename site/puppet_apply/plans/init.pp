plan puppet_apply(
  Targetspec $nodes,
  String[1] $code,
  Optional[String[1]] $modules = undef,
) {

  unless($modules == undef) {
    run_task('puppet_module::install', $nodes, 'modules' => $modules)
  }

  run_task('puppeteer::apply', $nodes, 'code' => $code)
}
