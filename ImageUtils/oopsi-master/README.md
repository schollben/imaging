### better algorithm/implementation for fast-oopsi now available

- https://github.com/j-friedrich/OASIS
- https://github.com/zhoupc/OASIS_matlab

imho, there is no reason to use this repo anymore unless you really want to use the particle filter based approach, 
i recommend that you use the above codes for python and matlab.

### oopsi algorithm info

This is a repo containing the most current code for doing model-based spike train inference from calcium imaging.  Manuscripts explaining the theory and providing some results on simulated and real data are available from the fast-oopsi, smc-oopsi, and pop-oopsi github repositories.  Those repositories also contain code that you may run and data to download to play with things.  Any question, ask them in the issues tab.  Please let me know of any positive or negative experiences.  Much Obliged, jovo

A question we often get is: "how shall we interpret the output? probability of spiking? instantaneous firing rate??

the answer is: yes, maybe :)

the "issue" is the lack of calibration data, 
which means we do not know the absolute size of a calcium transient evoked from a single spike.
we estimate it from the data, but if the neuron happens to always spike twice, for example, 
our estimate will be off by a factor of 2.

we can think of the above this way: is it likely that the neuron to spikes multiple times per time bin?

if so, i don't normalize the output, and interpret it as the instantaneous firing rate.

if not, i normalize the output so that its max is 1, and then i interpret it as the probability of a spike.

i hope this helps!

if not, please post issues [here](https://github.com/jovo/oopsi/issues)

