hugo_cmd = function(...) {
  system2(find_hugo(), ...)
}

# build a Hugo site using / as the basedir, and theme in config.yaml if
# configured (otherwise use the first dir under /themes/)
hugo_build = function(config = load_config()) {
  hugo_cmd(c(
    '-b', "/", '-t',
    get_config('theme', list.files(get_config('themesdir', 'themes', config))[1], config)
  ))
}

#' Run Hugo commands
#'
#' Wrapper functions to run Hugo commands via \code{\link{system2}('hugo',
#' ...)}.
#' @param dir The directory of the new site.
#' @param force Whether to create a new site in an existing directory. The
#'   default value is \code{TRUE} if none of the files/directories to be
#'   generated exist in this directory, otherwise \code{FALSE}, to make sure
#'   your existing files are not overwritten.
#' @param sample Whether to add sample content. Hugo creates an empty site by
#'   default, but this function adds sample content by default).
#' @param theme A Hugo theme on Github (a chararacter string of the form
#'   \code{user/repo}).
#' @param theme_example Whether to copy the example in the \file{exampleSite}
#'   directory if it exists in the theme. Not all themes provide example sites.
#' @param serve Whether to start a local server to serve the site.
#' @references The full list of Hugo commands: \url{https://gohugo.io/commands},
#'   and themes: \url{http://themes.gohugo.io}.
#' @export
#' @describeIn hugo_cmd Create a new site (skeleton) via \command{hugo new
#'   site}.
new_site = function(
  dir = '.', force, format = 'yaml', sample = TRUE,
  theme = 'dim0627/hugo_theme_robust', theme_example = TRUE, serve = TRUE
) {
  if (missing(force)) {
    force = FALSE
    files = intersect(
      list.files(dir),
      c('archetypes', 'config.toml', 'content', 'data', 'layouts', 'static', 'themes')
    )
    force = length(files) == 0
  }
  if (hugo_cmd(
    c('new site', shQuote(dir), if (force) '--force', '-f', format),
    stdout = FALSE
  ) != 0) return(invisible())

  owd = setwd(dir); on.exit(setwd(owd), add = TRUE)
  if (sample) {
    dir_create(file.path('content', 'post'))
    file.copy(pkg_file('resources', 'hello-world.Rmd'), 'content/post/')
  }
  if (is.character(theme)) in_dir('themes', {
    zipfile = sprintf('%s.zip', basename(theme))
    download2(
      sprintf('https://github.com/%s/archive/master.zip', theme), zipfile, mode = 'wb'
    )
    files = utils::unzip(zipfile)
    zipdir = dirname(files[1])
    expdir = file.path(zipdir, 'exampleSite')
    if (theme_example && dir_exists(expdir)) {
      file.copy(list.files(expdir, full.names = TRUE), '../', recursive = TRUE)
    }
    file.rename(zipdir, gsub('-master$', '', zipdir))
    unlink(zipfile)
  })
  if (serve) serve_site()
}

#' @param path The path to the new file.
#' @param format The format of the configuration file or the frontmatter of the
#'   new (R) Markdown file.
#' @param kind The content type to create.
#' @param editor Whether to open the new file after creating it. By default, it
#'   is opened in an interactive R session.
#' @export
#' @describeIn hugo_cmd Create a new (R) Markdown file via \command{hugo new}
#'   (e.g. a post or a page).
new_content = function(path, format = 'yaml', kind = NA, editor = interactive()) {
  hugo_cmd(c('new', shQuote(path), '-f', format, if (!is.na(kind)) c('-k', kind)))
  if (interactive()) file.edit(file.path(get_config('contentdir', 'content'), path))
}