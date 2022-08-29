function [ opts ] = lfadsMakeOptsSimple( )
    %default options strcut for all LFADS options
    opts.kind = 'train'; %'train', 'posterior_sample_and_average'
    opts.data_dir = '';
    opts.data_filename_stem = '';
    opts.lfads_save_dir = '';
    opts.co_dim = 0;
    opts.factors_dim = 20;
    opts.ext_input_dim = 0;
    opts.controller_input_lag = 1;
    opts.output_dist = 'poisson'; %'poisson','gaussian'
    opts.do_causal_controller = 'false';
    opts.keep_prob = 0.95;
    opts.con_dim = 128;
    opts.gen_dim = 200;
    opts.ci_enc_dim = 128;
    opts.ic_dim = 64;
    opts.ic_enc_dim = 128;
    opts.ic_prior_var_min = 0.1;
    opts.gen_cell_input_weight_scale = 1.0;
    opts.cell_weight_scale = 1.0;
    opts.do_feed_factors_to_controller = 'true';
    opts.kl_start_step = 0;
    opts.kl_increase_steps = 2000;
    opts.kl_ic_weight = 1.0;
    opts.l2_con_scale = 0.0;
    opts.l2_gen_scale = 2000;
    opts.l2_start_step = 0;
    opts.l2_increase_steps = 2000;
    opts.ic_prior_var_scale = 0.1;
    opts.ic_post_var_min = 0.0001;
    opts.kl_co_weight = 1.0;
    opts.prior_ar_nvar = 0.1;
    opts.cell_clip_value = 5.0;
    opts.max_ckpt_to_keep_lve = 5;
    opts.do_train_prior_ar_atau = 'true';
    opts.co_prior_var_scale = 0.1;
    opts.csv_log = 'fitlog';
    opts.feedback_factors_or_rates = 'factors';
    opts.do_train_prior_ar_nvar = 'true';
    opts.max_grad_norm = 200;
    opts.device='gpu:0';
    opts.num_steps_for_gen_ic = 100000000;
    opts.ps_nexamples_to_process = 100000000;
    opts.checkpoint_name = 'lfads_vae';
    opts.temporal_spike_jitter_width = 0;
    opts.checkpoint_pb_load_name = 'checkpoint';
    opts.inject_ext_input_to_gen = 'false';
    opts.co_mean_corr_scale = 0;
    opts.gen_cell_rec_weight_scale = 1;
    opts.max_ckpt_to_keep = 5;
    opts.output_filename_stem = '""';
    opts.ic_prior_var_max = 0.1;
    opts.prior_ar_atau = 10;
    opts.do_train_io_only = 'false';
    opts.batch_size=128;
    opts.learning_rate_init=0.01;
    opts.learning_rate_stop=1e-05;
    opts.learning_rate_decay_factor=0.95;
    opts.learning_rate_n_to_compare=6;
    opts.do_reset_learning_rate=false;
end

