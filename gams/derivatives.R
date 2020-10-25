library(gratia)
load_mgcv()
library(dplyr)
library(ggplot2)


ibd <- readRDS(("C:\\Users\\diaz.renata\\Documents\\GitHub\\BBSsize\\analysis\\isd_data\\ibd_isd_bbs_rtrg_19_35.Rds"))

sv <- ibd %>%
  group_by(year) %>%
  summarize(richness = length(unique(id)),
            abundance = dplyr::n(),
            biomass = sum(ind_size),
            energy = sum(ind_b)) %>%
  ungroup() %>%
  mutate(mean_energy = energy / abundance,
         mean_mass = biomass/abundance)

#### abundance

realplot <- ggplot(sv, aes(year, abundance)) + geom_line()

nmod <-  gam(abundance ~ s(year), data = sv, method = "REML")
#
# object <- nmod
# smooth_ids <- seq_len(n_smooths(object))
# type <- "central"
# need_newdata <- TRUE
# interval <- "confidence"
# n = 200
# eps = 1e-07
# offset = NULL
# order = 1
#
# Vb <- gratia:::get_vcov(object, unconditional = F, frequentist = F)
# betas <- coef(object)
# ns <- length(smooth_ids)
# result <- vector(mode = "list", length = ns)
for (i in seq_along(smooth_ids)) {
  if (need_newdata) {
    newdata <- gratia:::derivative_data(object, id = smooth_ids[[i]],
                                        n = n, offset = offset, order = order, type = type,
                                        eps = eps)
  }
  fd <- gratia:::finite_diff_lpmatrix(object, type = type, order = order,
                                      newdata = newdata, h = eps)
  X <- gratia:::finite_difference(fd, order, type, eps)
  d <- gratia:::compute_derivative(smooth_ids[[i]], lpmatrix = X,
                          betas = betas, Vb = Vb, model = object, newdata = newdata)
  if (identical(interval, "confidence")) {
    result[[i]] <- derivative_pointwise_int(d[["deriv"]],
                                            level = level, distrib = "normal")
  }
  else {
    result[[i]] <- gratia:::derivative_simultaneous_int(d[["deriv"]],
                                               d[["Xi"]], level = .95, Vb = Vb, n_sim = 2,
                                               ncores = 1)
  }
}

Xi = d[["Xi"]]
x = d[["deriv"]]
buDiff <- mvnfast ::rmvn(n = 5, mu = rep(0, nrow(Vb)), sigma = Vb,
               ncores = 1)
simDev <- tcrossprod(Xi, buDiff)
absDev <- abs(sweep(simDev, 1L, x[["se"]], FUN = "/"))
masd <- apply(absDev, 2L, max)
crit <- quantile(masd, prob = level, type = 8)
adj <- (crit * x[["se"]])
derivative <- add_column(x, crit = rep(crit, nrow(x)), lower = x[["derivative"]] -
                           adj, upper = x[["derivative"]] + adj)
derivative
