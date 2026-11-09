while (1) {
    clear

    # Top plot: Residuals
    set title "Residuals"
    set xlabel 'Iteration'
    set ylabel 'Residual'
    set logscale y
    plot "< grep 'Solving for Ux' log.buoyant | cut -d' ' -f9 | tr -d ',' | nl -v 0" title 'Ux' with lines,\
         "< grep 'Solving for Uy' log.buoyant | cut -d' ' -f9 | tr -d ',' | nl -v 0" title 'Uy' with lines,\
         "< grep 'Solving for p'  log.buoyant | cut -d' ' -f9 | tr -d ',' | nl -v 0" title 'p' with lines,\
         "< grep 'Solving for T'  log.buoyant | cut -d' ' -f9 | tr -d ',' | nl -v 0" title 'T' with lines,\

    pause 1
}
