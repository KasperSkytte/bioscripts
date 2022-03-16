runFromR <- function(command, args) {
  req_pkgs <- c("processx")
  pkg_status <- lapply(req_pkgs, require, character.only = TRUE)
  if (!all(unlist(pkg_status))) {
    stop(
      "The following packages are required, please install manually:\n",
      paste(req_pkgs, collapse = "\n"), call. = FALSE
    )
  }
  env = c(
    PATH = "/home/kapper/Software/bin:
          /home/kapper/Software/miniconda3/bin:
          /home/kapper/bin:
          /usr/local/sbin:
          /usr/local/bin:
          /usr/sbin:
          /usr/bin:
          /sbin:
          /bin:
          /snap/bin")
  res <- processx::run(
    command = command, 
    args = args,
    echo_cmd = TRUE,
    echo = TRUE,
    supervise = TRUE,
    error_on_status = TRUE,
    env = env)
  invisible(res)
}