function r=appleClassifier

% SETUP PHASE
%%%%%%%%%%%%%%%%%%%%%%%%%
% Set up apple training, training GT, test and test GT images
% as filepath strings sorted within cells.

if( ~exist('apples', 'dir') || ~exist('testApples', 'dir') )
    display('Please change current directory to the parent folder of both apples/ and testApples/');
end

% Note that cells are accessed using curly-brackets {} instead of parentheses ().
Iapples = cell(3,1);
Iapples{1} = 'apples/Apples_by_kightp_Pat_Knight_flickr.jpg';
Iapples{2} = 'apples/ApplesAndPears_by_srqpix_ClydeRobinson.jpg';
Iapples{3} = 'apples/bobbing-for-apples.jpg';

IapplesMasks = cell(3,1);
IapplesMasks{1} = 'apples/Apples_by_kightp_Pat_Knight_flickr.png';
IapplesMasks{2} = 'apples/ApplesAndPears_by_srqpix_ClydeRobinson.png';
IapplesMasks{3} = 'apples/bobbing-for-apples.png';

ItestApples = cell(5,1);
ItestApples{1} = 'testApples/Apples_by_MSR_MikeRyan_flickr.jpg';
ItestApples{2} = 'testApples/Bbr98ad4z0A-ctgXo3gdwu8-original.jpg';
ItestApples{3} = 'testApples/audioworm-QKUJj2wmxuI-original.jpg';
ItestApples{4} = 'testApples/5017861149_156ba10069_z.jpg';
ItestApples{5} = 'testApples/7974377626_0dfb28fcae_z.jpg';

ItestApplesMasks = cell(1,1);
ItestApplesMasks{1} = 'testApples/Bbr98ad4z0A-ctgXo3gdwu8-original.png';
ItestApplesMasks{2} = 'testApples/5017861149_156ba10069_z_mask.jpg';
ItestApplesMasks{3} = 'testApples/7974377626_0dfb28fcae_z_mask.jpg';

% TRAINING PHASE
%%%%%%%%%%%%%%%%
% Get RGB values for all training images, and corresponding true
% classifications. Fit the apple RGB values to one 3D Gaussian,
% and fit the non-apple values to another.

RGBApple = [];
RGBNonApple = [];

for iImage = 1:size(Iapples)
    curI = double(imread(  Iapples{iImage}   )) / 255;
    % curI is now a double-precision 3D matrix of size (width x height x 3). 
    % Each of the 3 color channels is now in the range [0.0, 1.0].
    % (because of the division by 255) -jim

    curImask = imread(  IapplesMasks{iImage}   );
    % These mask-images are often 3-channel, and contain grayscale values. We
    % would prefer 1-channel and just binary:
    curImask = curImask(:,:,2) > 128;  % Picked green-channel arbitrarily.

    % Reshape 3D RGB matrix into dxn 2D matrix to be logically indexed.
    % Permute into a suitable form, as 'reshape' works column-wise.
    curI = permute(curI,[3,2,1]);
    curI = reshape(curI,3,[]);

    % Reshape 2D logical GT mask into a 1xn array.
    % We want read row-wise so transpose curImask before reshape.
    % (as reshape works column-wise).
    apple_indices = reshape(curImask',1,[]);
    nonapple_indices = logical( ones(1,length(apple_indices)) ...
        - apple_indices );
    
    this_appleRGB = curI(:,apple_indices);
    this_nonappleRGB = curI(:,nonapple_indices);
    
    RGBApple = horzcat(RGBApple,this_appleRGB);
    RGBNonApple = horzcat(RGBNonApple,this_nonappleRGB);

end

% FIT individual Gaussians for the binary classifications

[meanApple covApple] = fitGaussianModel(RGBApple);
[meanNonApple covNonApple] = fitGaussianModel(RGBNonApple);
fprintf('Training complete.');

% PRIORS for apple and non-apple.
priorApple = 0.3;
priorNonApple = 0.7;

% TEST PHASE
%%%%%%%%%%%%%%%%%%%

for iImage = 1:size(ItestApples)
     break %%% REMOVE FOR TESTING

    % Load in test image.
    im = imread(ItestApples{iImage});
    % Display test image.
    figure; set(gcf,'Color',[1 1 1]);
    subplot(1,2,1); imagesc(im); axis off; axis image;
    drawnow;

    % Put into [0,1] RGB form.
    im = double(im) / 255;



    %now run through the pixels in the image and classify them as being skin or
    %non skin - we will fill in the posterior
    [imY imX imZ] = size(im);

    posteriorApple = zeros(imY,imX);
    for (cY = 1:imY);    
        for (cX = 1:imX);          
            %extract this pixel data
            thisPixelData = squeeze(double(im(cY,cX,:)));
            %calculate likelihood of this data given apple model
            likeApple = calcGaussianProb(thisPixelData,meanApple,covApple);
            %calculate likelihood of this data given non apple model
            likeNonApple = calcGaussianProb(thisPixelData,meanNonApple,covNonApple);
            posteriorApple(cY,cX) = (likeApple * priorApple) / ...
                (likeApple * priorApple + likeNonApple * priorNonApple);
        end;
    end;

    %draw apple posterior
    subplot(1,2,2); imagesc(posteriorApple); colormap(gray); axis off; axis image;
    % set(gca, 'clim', [0, 1]);
end

% ROC ANALYSIS
%%%%%%%%%%%%%

% Read in the image and GT mask for apple-and-orange test image.
im = double(imread(  ItestApples{2}   )) / 255;

figure; set(gcf,'Color',[1 1 1]);
    subplot(1,3,1); imagesc(im); axis off; axis image;

Imask = imread(  ItestApplesMasks{1}   );
Imask = Imask(:,:,2) > 128;  % Picked green-channel arbitrarily.
subplot(1,3,2); imagesc(Imask); colormap(gray); axis off; axis image;
drawnow;

% Image dimensions and number of pixels. 
[imY imX imZ] = size(im);
npix = numel(im);

posteriorApple = zeros(imY,imX);
for (cY = 1:imY);    
    break %%REMOVE WHEN COMPUTING POSTERIOR
    for (cX = 1:imX);          
        %extract this pixel data
        thisPixelData = squeeze(double(im(cY,cX,:)));
        %calculate likelihood of this data given apple model
        likeApple = calcGaussianProb(thisPixelData,meanApple,covApple);
        %calculate likelihood of this data given non apple model
        likeNonApple = calcGaussianProb(thisPixelData,meanNonApple,covNonApple);
        posteriorApple(cY,cX) = (likeApple * priorApple) / ...
            (likeApple * priorApple + likeNonApple * priorNonApple);
    end;
end;
%csvwrite('roc_posterior.dat', posteriorApple);
posteriorApple = csvread('roc_posterior.dat');
subplot(1,3,3); imagesc(posteriorApple); colormap(gray); axis off; axis image;

% Create array of discriminant thresholds to test.
discrim_vals = linspace(0,1,500);
% Initialise TP/TN/FP/FN rate arrays for assessing classification.
tp = zeros(1,length(discrim_vals));
tn = zeros(1,length(discrim_vals));
fp = zeros(1,length(discrim_vals));
fn = zeros(1,length(discrim_vals));

n_true = nnz(Imask);
n_neg = nnz(ones(imY,imX) - Imask);

for (d = 1:length(discrim_vals))
    % Classification results for this threshold.
    result = posteriorApple >= discrim_vals(d);
    
    % Determine TP/TN/FP/FN matrices for this result.
    tp_mat = result == 1 & Imask == 1;
    tn_mat = result == 0 & Imask == 0;
    fp_mat = result == 1 & Imask == 0;
    fn_mat = result == 0 & Imask == 1;
    
    
    % Count, normalise and append.
    tp(d) = nnz(tp_mat) / n_true;
    tn(d) = nnz(tn_mat) / n_neg;
    fp(d) = nnz(fp_mat) / n_neg;
    fn(d) = nnz(fn_mat) / n_true;
end

figure
semilogx(fp,tp);
title('ROC curve (part D)');
xlabel('False positive rate');
ylabel('True positive rate');
drawnow

    
 
%==========================================================================
%==========================================================================

%the goal of this routine is to evaluate a Gaussian likleihood
function like = calcGaussianProb(data,gaussMean,gaussCov)

[nDim nData] = size(data);


constant = 1 / ( (2*pi)^(nDim/2) * sqrt(det(gaussCov)));

% Likelihood incrementer. 1 is the product identity.
like = 1;

for n = 1:nData
    meandiffs = (data(:,n) - gaussMean);
    power = -0.5 * meandiffs' * inv(gaussCov) * meandiffs;
    exponent = exp(power);

    % Update likelihood
    like = like * constant * exponent;
end




%==========================================================================
%==========================================================================

%the goal of this routine is to return the mean and covariance of a set of
%multidimensaional data.  It is assumed that each column of the 2D array
%data contains a single data point.  The mean vector should be a 3x1 vector
%with the mean RGB value.  The covariance should be a 3x3 covariance
%matrix. See the note at the top, which explains that using mean() is ok,
%but please compute the covariance yourself.
function [meanData covData] = fitGaussianModel(data);

% Looks like this is how one assigns two variables.
[nDim nData] = size(data);


%calculate mean of data.  You can do this using the MATLAB command 'mean'
meanData = mean(data,2);

%calculate covariance of data.  You should do this yourself to ensure you
%understand how.  Check you have the right answer by comparing with the
%matlab command 'cov'.
covData = zeros(nDim,nDim);
for m = 1:nDim
    m_data = data(m,:);
    for n = 1:nDim
        n_data = data(n,:);
        exy = mean(m_data .* n_data);
        exey = mean(m_data) * mean(n_data);
        mn_cov = exy - exey;
        covData(m,n) = mn_cov;
    end
end

