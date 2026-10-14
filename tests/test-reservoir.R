source('tests/helper.R'); source_test_runtime()
# Prefix sampling would never retain a late value. Batch replacements must use
# the final replacement for each destination, and state stays bounded.
sample_run <- function(seed,chunk=100L) {
 set.seed(seed); state <- list(values=numeric(),seen=0)
 for(start in seq(1,1000,by=chunk)) state <- numeric_reservoir_update(state,start:min(1000,start+chunk-1),20L)
 state
}
a <- sample_run(173)
expect_equal(a,sample_run(173)); expect_equal(length(a$values),20L)
expect_equal(a$seen,1000); expect_true(any(a$values>900))
for(chunk in c(1L,73L,1000L)) {
 means <- vapply(1:150,function(seed)mean(sample_run(seed,chunk)$values),numeric(1))
 expect_true(abs(mean(means)-500.5)<35,'Reservoir must include the whole stream across chunk sizes.')
}
cat('PASS bounded reproducible reservoir distribution\n')
