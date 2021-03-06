#include <iostream>
#include <thread>
#include <random>
#include <cstdint>

#include "particle_initializer.h"
//for GPU simulations instead of particle_simulation.h
#include "particle_simulation_GPU.cu"

//Example file intended to show how a GPU simulation is set up and performed
//Example is saturn orbited by particles in the postion of saturns ring

int main(){
  //Values for the AVX2 computation are somewhat irrelevant for the GPU
  //computation, in that their value is irrelevant for the computation but they
  //are still needed for the constructor of ParticleSimulation
  constexpr int num_double_in_SIMD_register = 4;  //avx2 -> 256bit -> 4 doubles

  constexpr int num_big_steps = 500; //quantifies samples in outputfile
  constexpr double t_delta = (60*60*18);
  constexpr double steps_per_second = 50;
  int64_t num_total_steps = ceil((steps_per_second * t_delta)
                                            /num_big_steps)*num_big_steps;
  int num_substeps_per_big_step = num_total_steps / num_big_steps;
  double stepsize = t_delta / num_total_steps;

  //parameters for the ring
  //Choose multiples of the blocksize for best per particle performance
  constexpr int num_particles = 2000;
  constexpr double v_deviation_sigma = 50;
  constexpr double disc_thickness_sigma = 50;
  constexpr double ring_radius = 1.12e+8;
  constexpr double ring_width_sigma = 3.0e+7;
  constexpr double mass_sigma = 0.1;

  int num_threads = 1;

  ParticleSimulation<double,num_double_in_SIMD_register> my_sim(num_particles,
    num_big_steps, num_substeps_per_big_step, stepsize, num_threads);

  //std::random_device r;
  //std::default_random_engine engine(r());
  std::default_random_engine engine(42);
  std::normal_distribution<double> disc_height_distro(0, disc_thickness_sigma);
  std::normal_distribution<double> disc_radius_distro(0, ring_width_sigma);
  std::uniform_real_distribution<double> phase_distro(0, 2*M_PI);
  std::normal_distribution<double> v_dev_distro(0, v_deviation_sigma);
  std::normal_distribution<double> mass_distro(0, mass_sigma);

  InPutParticle<double> input;
  input = BodyAtCenter<double>(5.683e+26);  //saturn
  my_sim.SetParticle(input.particle, input.m);

  //Ringparticles
  for(int i=1; i<num_particles; i++){
    double x_deviation[3] = {0.0, 0.0, disc_height_distro(engine)};
    double y_deviation[3] = {v_dev_distro(engine), v_dev_distro(engine), 0.0};
    input = NonCircularOrbitMoon<double>(x_deviation, y_deviation,
                                 phase_distro(engine),
                                 0.0, 0.0, true, 5.683e+26,
                                 pow(mass_distro(engine), 2),
                                 ring_radius + disc_radius_distro(engine));
    my_sim.SetParticle(input.particle, input.m);
  }

  //Is neccesary if N % num_double_in_SIMD_register != 0 (so not needed here)
  my_sim.SetMissingParticlesInBatch();

  //perform Simulation
  std::cout << my_sim.SimulateGPU(32) << std::endl;

  //my_sim.WriteParticleFiles("");
  my_sim.WriteTimestepFiles("");

  my_sim.PrintAverageStepTime();
}
