function [output_image] = LRTV_SATV(oriData3_noise, tau,lambda, r)
%%%% LRTV + SATV


% Solve problem
% solve the following problem (TV regularized LR and MC problem)
%  argmin   ||L||_nuclear + tao * ||X||_TV+lanbda*||E||_1
%                       s.t. X = L D = L + E and rank(L)<=r;
%     via IALM 
% -------------------------------------------------------------------------------------------------------------
% Reference paper: 
%[1]H. Zhang, W. He, L. Zhang, H. Shen, and  Q. Yuan, ��Hyperspectral Image 
%   Restoration Using Low-Rank Matrix Recovery,��IEEE Trans. Geosci. Remote Sens. ,
%    vol. 52, pp. 4729-4743, Aug. 2014.
%[2]W. He, H. Zhang, L. Zhang, and  H. Shen, ��Total-Variation-Regularized Low-Rank Matrix Factorization for
%  Hyperspectral Image Restoration,�� IEEE Trans. Geosci. Remote Sens., vol. 54, pp. 178-188, Jan. 2016.
 
% Author: Wei He (November, 2014)
% E-mail addresses:(weihe1990@whu.edu.cn)
% --------------------------------------------------INPUT-----------------------------------------------------
%  oriData3_noise                            noisy 3-D image of size M*N*p normalized to [0,1] band by band
%  tau                                       (recommended value 0.01)              
%  lambda 
%  r                                         rank constraint
% --------------------------------------------------OUTPUT-----------------------------------------------------
%  output_iamge                              3-D denoised image
%  out_value                                 MPSNR and MSSIM valuses of each iteration 
% -------------------------------------------------------------------------------------------------------------

% -------------------------------------------------------------------------------------------------------------
[M N p] = size(oriData3_noise);
D = zeros(M*N,p);

for i=1:p 
  bandp  = oriData3_noise(:,:,i);
  D(:,i) = bandp(:); 
end
[d p] = size(D);

d_norm = norm(D, 'fro');

% initialize
% b_norm = norm(D, 'fro');
tol = 1e-6;
tol1 = tol;
tol2 = tol1;
maxIter = 60; %maxIter = 40;

rho = 1.5;
max_mu1 = 1e6;
mu1 = 1e-2;
mu2  = mu1;
mu3 = mu2;
sv =10;
%% 
out_value = [];
out_value.SSIM =[];
out_value.PSNR =[];
%% Initializing optimization variables
% intialize
% L = zeros(d,p);
% X = zeros(d,p);
% TM = zeros(d,p);
L = rand(d,p);
X = L;
E = sparse(d,p);

Y1 = zeros(d,p);
Y2 = zeros(d,p);

% for the TV norm
param2.verbose=1;
%param2.max_iter=20;
param2.max_iter=100;
param2.verbose = 0;
% g1.prox=@(x, T) prox_TV(x, T*mu1/(2*tau), param2);
% g1.norm=@(x) tau*TV_norm(x); 


%%%%% main loop
iter = 0;
tic
while iter<maxIter
    iter = iter + 1;      

%     Updata L
temp = (mu1*X +mu2* (D-E) + (Y1+Y2))/(mu1+mu2);
if  choosvd(p,sv) ==1
    [U, sigma, V] = lansvd(temp, sv, 'L');
else
    [U,sigma,V] = svd(temp,'econ');
end
    sigma = diag(sigma);
    svp = min(length(find(sigma>1/(mu1+mu2))),r);
    if svp<sv
        sv = min(svp + 1, p);
    else
       sv = min(svp + round(0.05*p), p);
        
    end
 L = U(:, 1:svp) * diag(sigma(1:svp) - 1/(mu1+mu2)) * V(:, 1:svp)'; 


 %       Updata X
temp = L - Y1/mu1;
X = L;

%%% SATV:   3 channel  simultaneously

lambdaSATV = 60; 

f = zeros(M,N,p);
for i =1:p      
z = double(reshape(temp(:,i),[M,N]));
f(:,:,i) = z(:,:);  
end

f = tvrestore(f,lambdaSATV,[],[],'L2');

for i =1: p
   X(:,i) = reshape(f(:,:,i), [1,M*N]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% updata E
temp_E = D - L + Y2/mu2;
E_hat = max(temp_E - lambda/mu2, 0);
E = E_hat+min(temp_E + lambda/mu2, 0);

leq1 = X - L;
leq2 = D -L -E ;
%% stop criterion          
%     stopC = max(max(max(abs(leq1))),max(max(abs(leq2))));
 
stopC1 = max(max(abs(leq1)));
stopC2 = norm(leq2, 'fro') / d_norm;
disp(['iter ' num2str(iter) ',mu=' num2str(mu1,'%2.1e')  ...
           ',rank = ' num2str(rank(L))  ',stopALM=' num2str(stopC2,'%2.3e')...
           ',stopE=' num2str(stopC1,'%2.3e')]);
 
 if stopC1<tol  & stopC2<tol2
   break;
 else
   Y1 = Y1 + mu1*leq1;
   Y2 = Y2 + mu2*leq2;
   mu1 = min(max_mu1,mu1*rho);
   mu2 = min(max_mu1,mu2*rho);  
 end
 
end
toc
output_image = reshape(L,[M,N,p]);
end

