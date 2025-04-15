
N=8;
n=0:N-1;
k=0:N-1;
k=k.';
t=k*(pi()/N*(n+.5));
dct = cos(t);
% dct = zeros(N);
% i = cos(pi()/N*(n+.5)*k);
%plot(cos(t))

A=imread('../images/my_cat.png');
A=mean(A,3);
B=filter2([.3,.3,.3;.3,.3,.3;.3,.3,.3],A);
C=A(1:3:end,1:3:end);
C2=B(1:3:end,1:3:end);
D=filter2([.3,.3,.3;.3,.3,.3;.3,.3,.3],C2);
E=D(1:3:end,1:3:end);
F=E(10:10+31,5:5+31);
F=F/max(max(F))*255;
% figure(1)
% imshow(F,[])
F=A;
imsize=size(F);
cols=imsize(2);
rows=imsize(1);

F=A(1:floor(rows/8)*8,1:floor(cols/8)*8);

qtable=[16 11 10 16 24 40 51 61;
        12 12 14 19 26 58 60 55;
        14 13 16 24 40 57 69 56;
        14 17 22 29 51 87 80 62;
        18 22 37 56 68 109 103 77;
        24 35 55 64 81 104 113 92;
        49 64 78 87 103 121 120 101;
        72 92 95 98 112 100 103 99;
        ];
filter=[1 1 1 1 1 1 1 1;
        1 1 1 1 1 1 1 1;
        1 1 1 1 1 1 1 1;
        1 1 1 1 1 1 1 1;
        1 1 1 1 1 1 1 1;
        1 1 1 1 1 1 1 1;
        1 1 1 1 1 1 1 1;
        1 1 1 1 1 1 1 1;
        ];
X=ones(32);
for i = 1:N:rows
    for j = 1:N:cols
        X(i:i+N-1,j:j+N-1)=dct*F(i:i+N-1,j:j+N-1)*dct.';
    end
end
Q=ones(32);
for i = 1:N:rows
    for j = 1:N:cols
        Q(i:i+N-1,j:j+N-1)=round(X(i:i+N-1,j:j+N-1)./qtable);
    end
end
q=ones(32);
for i = 1:N:rows
    for j = 1:N:cols
        q(i:i+N-1,j:j+N-1)=inv(dct)*(Q(i:i+N-1,j:j+N-1).*qtable.*filter)*inv(dct.');
    end
end


%X=dct*F*dct.';
%Q=round(X./qtable);

% figure(4)
% imshow(X,[])
% figure(5)
% imshow(Q,[])
% figure(6)
% imshow(q,[])
subplot(1,3,1)
imshow(F,[])
subplot(1,3,2)
imshow(Q,[])
subplot(1,3,3)
imshow(q,[])
err=F-q;
% subplot(1,4,4)
% imshow(F-q,[])
%imshow(inv(dct)*(Q*100)*inv(dct.'),[]);


% i = 1:N;
% x=cos(i*2*pi()/20);
% X=dct*x.';
% figure(1)
% plot(x)
% hold
% plot(inv(dct)*X);
% figure(2)
% plot(X)


