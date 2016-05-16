/*********************************
 *****   lpcencoder.         *****
 *********************************/


/* 1. Window the data 
FLAC__lpc_window_data(integer_signal, 
                      encoder->private_->window[a],
                      encoder->private_->windowed_signal, 
                      frame_header->blocksize);
                      
   2. Calculate the autocorrelation of the input data 
encoder->private_->local_lpc_compute_autocorrelation(encoder->private_->windowed_signal, 
                                                    frame_header->blocksize, 
                                                    max_lpc_order+1,
                                                    autoc);

 3. Solve the linear equation using levinson-durbin recursion equation 
 FLAC__lpc_compute_lp_coefficients(autoc, 
                                   &max_lpc_order, 
                                   encoder->private_->lp_coeff, 
                                   lpc_error);
 
 3. Obtain appropriate coefficients 
 

 4. Compute residuals */




void LPCEncoder::calc_autocorrelation(int32_t samples[], int nsamples, int order, int32_t autoc[]){
    double d;
    unsigned i;
    
    /* Autocorrelation is defined as: 
     * 
     * 
     * Since audio signals tend to have a mean of 0, we don't need to subtract
     * the mean from the data.
     */
    
    for (int i = 0; i < order - 1; i++){
        for (int j = 0; j < nsamples - i; j++){
            autoc[i] += samples[j]*samples[j + i];
        }
    }
    /*
    while(order--) {
        for(i = order, d = 0.0; i < data_len; i++)
            d += data[i] * data[i - order];
        autoc[order] = d;
    }*/
}

void LPCEncoder::calculate_lpc_coeffs(int32_t autoc[], int order, int32_t lpc_coeff[])