clear all
close all
clc

I = double(imread('barbara.bmp'))/255;

tau = 0.015; 
lambda = 0.5; 
rank = 10; 

S = LRTV_SATV(I, tau,lambda, rank);

T = I-S;

imshow(S);