//finds the best correlation between two images given a range of different overlaps
//so, it's just a constrained cross correlation.

#include <math.h>
#include <matrix.h>
#include <mex.h>

template<typename T> void corr2(T* movingImg, T* fixedImg, 
        size_t imgSizeY, size_t imgSizeX,
        double minOffsetY, double maxOffsetY, 
        double minOffsetX, double maxOffsetX,
        double* bestCorrY, double* bestCorrX){
    //Computes the correlation of the moving image and the template at a given position
    //Position describes where the moving image is relative to the template
    //e.g. posX of -3 indicates that the movingImage is 3 left of the template. 
    
    double bestCorrValue = -1;
    *bestCorrY = minOffsetY;
    *bestCorrX = minOffsetX;
    
    for(int posY=minOffsetY; posY <= maxOffsetY; posY++){
        for(int posX=minOffsetX; posX <= maxOffsetX; posX++){
            //define the overlap box
            int mxStart = 0;
            int myStart = 0;
            int fxStart = 0;
            int fyStart = 0;

            if(posX < 0)
                mxStart = -posX;
            else
                fxStart = posX;

            if(posY < 0)
                myStart = -posY;
            else
                fyStart = posY;

            int overlapX, overlapY;

            if((imgSizeX-mxStart)<(imgSizeX-fxStart))
                overlapX = imgSizeX-mxStart;
            else
                overlapX = imgSizeX-fxStart;

            if((imgSizeY-myStart)<(imgSizeY-fyStart))
                overlapY = imgSizeY-myStart;
            else
                overlapY = imgSizeY-fyStart;

            int overlapArea = overlapX*overlapY;

            //find template mean and movingImage mean within overlap box
            double fOverlapMean = 0;
            double mOverlapMean = 0;

            for(int x = 0; x < overlapX; x++){
                int fX = (x+fxStart)*imgSizeY;
                int mX = (x+mxStart)*imgSizeY;
                for(int y = 0; y < overlapY; y++){
                    fOverlapMean += fixedImg[y+fyStart+fX];
                    mOverlapMean += movingImg[y+myStart+mX];
                }
            }
            mOverlapMean /= overlapArea;
            fOverlapMean /= overlapArea;


            //find standard devs
            double fOverlapDiffSq = 0;
            double mOverlapDiffSq = 0;
            for(int x = 0; x < overlapX; x++){
                int fX = (x+fxStart)*imgSizeY;
                int mX = (x+mxStart)*imgSizeY;
                for(int y = 0; y < overlapY; y++){
                    fOverlapDiffSq += pow((fixedImg[y+fyStart+fX] - fOverlapMean), 2);
                    mOverlapDiffSq += pow((movingImg[y+myStart+mX] - mOverlapMean), 2);
                }
            }
            double denom = sqrt(fOverlapDiffSq * mOverlapDiffSq);

            //compute correlation of values in overlap box
            double numer = 0;
            for(int x = 0; x < overlapX; x++){
                int fX = (x+fxStart)*imgSizeY;
                int mX = (x+mxStart)*imgSizeY;
                for(int y = 0; y < overlapY; y++){
                    double fVal = fixedImg[y+fyStart+fX];
                    double mVal = movingImg[y+myStart+mX];

                    numer += (mVal-mOverlapMean)*(fVal-fOverlapMean);
                }
            }

            if(abs(denom) > 0){
                double corrValue = numer / denom;
                if(corrValue > bestCorrValue){
                    bestCorrValue = corrValue;
                    *bestCorrY = posY;
                    *bestCorrX = posX;
                }
            }
        }
    }
    
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	// Check input
	if (nlhs != 2) {
		mexErrMsgTxt("Usage: [bestCorrY, bestCorrX] = corr2max(movingImg, fixedImg, minOffsetY, maxOffsetY, minOffsetX, maxOffsetX);");
	}
	if (nrhs != 6) {
		mexErrMsgTxt("Usage: [bestCorrY, bestCorrX] = corr2max(movingImg, fixedImg, minOffsetY, maxOffsetY, minOffsetX, maxOffsetX);");
	}

    void *movingImg = mxGetData(prhs[0]);
    mxClassID mClass = mxGetClassID(prhs[0]);
    
    void *fixedImg = mxGetData(prhs[1]);
    mxClassID fClass = mxGetClassID(prhs[1]);
    
    //filter out any weird inputs that could crash us
    if(mClass != fClass){
        //just makes life a lot easier
        mexErrMsgTxt("Moving and fixed images must be the same type!");
    }
    
    if(mxGetClassID(prhs[2]) != mxDOUBLE_CLASS ||
            mxGetClassID(prhs[3]) != mxDOUBLE_CLASS ||
            mxGetClassID(prhs[4]) != mxDOUBLE_CLASS ||
            mxGetClassID(prhs[5]) != mxDOUBLE_CLASS){
        mexErrMsgTxt("Offsets must be of type 'double'.");
    }

    double *minOffsetY = mxGetPr(prhs[2]);
    double *maxOffsetY = mxGetPr(prhs[3]);
    double *minOffsetX = mxGetPr(prhs[4]);
    double *maxOffsetX = mxGetPr(prhs[5]);
    
    
    if(mClass == mxCELL_CLASS || 
            mClass == mxOBJECT_CLASS || 
            mClass == mxSTRUCT_CLASS  ||
            mClass == mxCHAR_CLASS ||
            mClass == mxSPARSE_CLASS ||
            mClass == mxUNKNOWN_CLASS){
        mexErrMsgTxt("Inputs must be images.");
    }
    
    if(mxGetNumberOfDimensions(prhs[0]) != 2){
        mexErrMsgTxt("Moving image must be 2-dimensional.");
    }
    if(mxGetNumberOfDimensions(prhs[1]) != 2){
        mexErrMsgTxt("Fixed image must be 2-dimensional.");
    }

    //Error checks complete! Call function with appropriate args.
    
    const int *mdim_array = mxGetDimensions(prhs[0]);
    size_t imgSizeY = mdim_array[0];
    size_t imgSizeX = mdim_array[1];
    
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    double *bestCorrY = mxGetPr(plhs[0]);
    plhs[1] = mxCreateDoubleMatrix(1, 1, mxREAL);
    double *bestCorrX = mxGetPr(plhs[1]);
    
    //handle different data types
    switch(mClass){
        case mxINT8_CLASS:
            corr2((char *)movingImg, (char *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
        case mxUINT8_CLASS:
            corr2((unsigned char *)movingImg, (unsigned char *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
        case mxINT16_CLASS:
            corr2((short *)movingImg, (short *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
        case mxUINT16_CLASS:
            corr2((unsigned short *)movingImg, (unsigned short *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
        case mxINT32_CLASS:
            corr2((int *)movingImg, (int *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
        case mxUINT32_CLASS:
            corr2((unsigned int *)movingImg, (unsigned int *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
        case mxINT64_CLASS:
            corr2((long *)movingImg, (long *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
        case mxUINT64_CLASS:
            corr2((unsigned long *)movingImg, (unsigned long *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
        case mxDOUBLE_CLASS:
            corr2((double *)movingImg, (double *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
        case mxSINGLE_CLASS:
            corr2((float *)movingImg, (float *)fixedImg, imgSizeY, imgSizeX, *minOffsetY, *maxOffsetY, *minOffsetX, *maxOffsetX, bestCorrY, bestCorrX);
            break;
    }
}


