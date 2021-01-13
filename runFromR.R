if(!require("processx"))
  install.packages("processx"); require("processx")
runFromR <- function(command, args) {
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