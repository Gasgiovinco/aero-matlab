clear all
close all

tic

global A b c Pleg w wp NV nx p dx dt IT BC_type V VIS F gamma

GHNC        = 0;
%CFL        = 0.9;
OUTTIME     = 0.1;
TAU			= 0.001% !RELAXATION TIME

nx = 32; % number of elements
p  = 4;			%polinomial degree
pp =p+1;
stage=6;
rk =stage;			%RK stage

BC_type = 0; % 0 No-flux; -1: reflecting
CFL=1/(2*p+1);
ratio=0.2;

bb=0;

coeffi_RK
gamma=const_a_I(2,1);


% filter_order=4;
% CutOff=0.75;
%
% filter_sigma=filter_profile(p,filter_order, CutOff)

IT = -1;
NV = 80;
NVh= NV/2;

[GH,wp] = GaussHermite(NV); % for integrating range: -inf to inf
wp=wp';
V=-GH';
wp=wp.*exp(V.^2);

dx=1/nx;		%Stepwidth in space
amax=abs(V(1));
fprintf('a_max = %0.6f\n',amax);

dt=CFL*dx*ratio/amax
dt=min(dt,TAU)

tol=[1.d-6,1.d-6]*dx;
parms = [40,40,-.1,1];


% Initial State

% Case 1
RL=1.0;
UL=0.75;
PL=1.0;

ET=PL+0.5*RL*UL^2;
TL=4*ET/RL-2*UL^2;
ZL=RL/sqrt(pi*TL);
%                         T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
%                         Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
%                         P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
RR=0.125;
UR=0;
PR=0.1;

ET=PR+0.5*RR*UR^2;
TR=4*ET/RR-2*UR^2;
ZR=RR/sqrt(pi*TR);

% Case 2
% UL  = 0.;
% TL  = 4.38385;
% ZL  = 0.2253353;
% UR  = 0.;
% TR  = 8.972544;
% ZR  = 0.1204582;

% UR  = UL;
% TR  = TL;
% ZR  = ZL;


%nt=round(OUTTIME/dt);
[xl,w]=gauleg(pp);
[Pleg]=legtable(xl,p);
MF=zeros(NV,NV);
F=zeros(NV,nx,pp);
FEQ=zeros(NV,nx,pp);
%Fd=zeros(NV,nx,pp);
F_tmp=zeros(NV,nx,pp);
F_new=zeros(NV,nx,pp);
FS=zeros(NV,nx,pp);
% Floc=zeros(NV,nx,pp);
F_loc=zeros(NV,pp);
SR=zeros(nx,pp);
SU=zeros(nx,pp);
SE=zeros(nx,pp);
SAV=zeros(nx,pp);
R=zeros(nx,pp);
P=zeros(nx,pp);
U=zeros(nx,pp);
T=zeros(nx,pp);
Z=zeros(nx,pp);
ET=zeros(nx,pp);
AV=zeros(nx,pp);
x=zeros(1,nx*pp);
ffunc=zeros(1,pp);
alpha=zeros(1,rk);

FR=zeros(pp,1);
FU=zeros(pp,1);
FC=zeros(pp,1);
FN=zeros(pp,1);

F_s=zeros(NV,nx,pp,stage);
F_ns=zeros(NV,nx,pp,stage);
%%%%%%%%%%%%%%  Transforming the initial condition to coefficients of Legendre Polinomials  %%%%%%%%%%%%%%%%%%%%
for i=1:nx
    xi=(2*i-1)*dx/2;      %evaluating the function `func' at the quadrature points
    x((i-1)*pp+1:i*pp)=xi+xl*dx/2;
    if(xi+xl(2)*dx/2 <= 0.5)
        U(i,:) = UL;
        T(i,:) = TL;
        Z(i,:) = ZL;
    else
        U(i,:) = UR;
        T(i,:) = TR;
        Z(i,:) = ZR;
    end
    
    for K = 1: NV
        for m=1:pp  %evaluating the function `func' at the quadrature points
            ffunc(m)  = 1/((exp((V(K)-U(i,m))^2/T(i,m))/Z(i,m)) + IT);
        end
        for j=0:p
            F(K,i,j+1)= sum (ffunc.*Pleg(j+1,:).*w)*(2*j+1)/2;
        end
    end
end

No=6;
[LG_grids_o,ValuesOFPolyNatGrids] = ZELEGL (No) ;
[LG_weights_o] = WELEGL (N_pl,LG_grids_o,ValuesOFPolyNatGrids) ;
for i=1:nx
    xi=(2*i-1)*dx/2;      %evaluating the function `func' at the quadrature points
    x((i-1)*pp+1:i*pp)=xi+xl*dx/2;
for j=1:No
 xo1(j)= x1(0,1,DDK)+(x1(PND1,1,DDK)-x1(0,1,DDK))*(LG_grids_o(ii)-LG_grids_o(0))/2d0
end
end

Tmin=min(TR,TL);
Tmax=max(TR,TL);

for i=1:nx
    Mtemp=zeros(NV,pp);
    for K=1:NV
        Mtemp(K,:)=F(K,i,:);
    end
    F_loc(:,:)=Mtemp*Pleg;
    for m=1:pp
        SR(i,:) = wp * F_loc;
        SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
        SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
        SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));
        
        R(i,m)    = SR(i,m);
        U(i,m)    = SU(i,m)/SR(i,m);
        ET(i,m)   = SE(i,m);
        AV(i,m)   = SAV(i,m);
        T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
        Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
    end
end

r_plot=reshape(R',nx*pp,1);
u_plot=reshape(U',nx*pp,1);
et_plot=reshape(ET',nx*pp,1);
p_plot=reshape(P',nx*pp,1);
t_plot=reshape(T',nx*pp,1);
z_plot=reshape(Z',nx*pp,1);
%scrsz = get(0,'ScreenSize');
if bb==1
    
    figure(1)
    %figure('Position',[scrsz(3)/4 scrsz(4)/8 scrsz(3)/2 scrsz(4)*3/4])
    subplot(2,3,1); wave_handleu = plot(x,u_plot,'.'); axis([0,1,-0.5,1.5]);
    xlabel('x'); ylabel('u(x,t)'); title('Velocity');
    subplot(2,3,2); wave_handler = plot(x,r_plot,'.'); axis([0,1,0,1.2]);
    xlabel('x'); ylabel('R(x,t)'); title('Density');
    subplot(2,3,3); wave_handleet = plot(x,et_plot,'.'); axis([0,1,0,2]);
    xlabel('x'); ylabel('ET(x,t)'); title('Energy');
    subplot(2,3,4); wave_handleav = plot(x,p_plot,'.'); axis([0,1,0,1.5]);
    xlabel('x'); ylabel('AV(x,t)');title('Pressure');
    subplot(2,3,5); wave_handlet = plot(x,t_plot,'.'); axis([0,1,3,4]);
    xlabel('x'); ylabel('T(x,t)'); title('temperature');
    subplot(2,3,6); wave_handlez = plot(x,z_plot,'.'); axis([0,1,0,1]);
    xlabel('x'); ylabel('Z(x,t)');title('Fugacity');
    
    drawnow
end

pause(0.2)

A=zeros(pp,pp);
b=zeros(1,pp);
c=zeros(1,pp);
for i=1:pp
    for j=1:pp
        if j>i && rem(j-i,2)==1
            A(i,j)=2;
        end
    end
    b(i)=(i-1/2)*2/dx;
    c(i)=(-1)^(i-1);
end
alpha(1)=1;
for m=1:rk
    for k=(m-1):(-1):1
        alpha(k+1)=1/k*alpha(k);
    end
    alpha(m)=1/factorial(m);
    alpha(1)=1-sum(alpha(2:m));
end

ITER  = 1;
TIME  = 0;
ISTOP = 0;
FC=zeros(pp,1);
FN=zeros(pp,1);
FB=zeros(pp,1);

while ISTOP ==0
    VIS(1:nx,1:pp) = TAU;
    
    TIME = TIME + dt;
    dtdx = dt/dx;
    
    if (TIME > OUTTIME)
        DTCFL = OUTTIME - (TIME - dt) ;
        TIME = OUTTIME;
        dt = DTCFL;
        dtdx = dt /dx;
        ISTOP = 1;
    end
    
    %%%%%%%%%%%%  Calculating the d(eta)/d(t) for every timestep i  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Fold=F;
    F_new=F;
    
    for l=1:rk
        
        if l==1
            for i = 1:nx
                for K = 1:NV
                    for m=1:pp
                        FEQ(K,i,m)   = 1/((exp( (V(K)-U(i,m))^2 /T(i,m))/Z(i,m)) + IT );
                    end
                end
            end
            
            for i=1:nx
                for K = 1: NV
                    FC(:)=F(K,i,:);
                    FB(:)=FEQ(K,i,:);
                    FC=(FC'*Pleg-FB')';
                    
                    for j=0:p
                        %         FS(K,i,j+1)=sum (FC'.*Pleg(j+1,:).*w)*(2*j+1)/2/VIS(i,j+1);
                        FS(K,i,j+1)=sum (FC'.*Pleg(j+1,:).*w)*dx/2/VIS(i,j+1);
                    end
                end
                
                
            end
            for K=1:NVh
                if BC_type == 0
                    %BC no-flux
                    FC(:)=F(K,1,:);
                    FU=FC;
                    FR(:)=FS(K,1,:);
                    F_s(K,1,:,1)=( (-FR)' .* b);
                    F_ns(K,1,:,1)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c')' .* b);
                elseif BC_type == -1            %BC reflecting
                    FC(:)=F(K,1,:);
                    FU(:)=F(NV-K+1,1,:);
                    FR(:)=FS(K,1,:);
                    F_s(K,1,:,1)=( (-FR)' .* b);
                    F_ns(K,1,:,1)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c')' .* b);
                else
                end
                for i=2:nx
                    FU(:)=F(K,i-1,:);
                    FC(:)=F(K,i,:);
                    FR(:)=FS(K,i,:);
                    F_s(K,i,:,1)=( (-FR)' .* b);
                    F_ns(K,i,:,1)=( (V(K)*A'*FC -V(K)* sum(FC) +V(K)* sum(FU) * c')' .* b);
                end
                
                for i=1:nx-1
                    FU(:)=F(NVh+K,i+1,:);
                    FC(:)=F(NVh+K,i,:);
                    FR(:)=FS(NVh+K,i,:);
                    F_s(NVh+K,i,:,1)=( (-FR)' .* b);
                    F_ns(NVh+K,i,:,1)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU'.* c) + V(NVh+K)*sum(FC'.* c) * c')' .* b);
                end
                if BC_type == 0
                    %BC no-flux
                    FC(:)=F(NVh+K,nx,:);
                    FU=FC;
                    FR(:)=FS(NVh+K,nx,:);
                    F_s(NVh+K,nx,:,1)=( (-FR)' .* b);
                    F_ns(NVh+K,nx,:,1)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c')' .* b);
                elseif BC_type == -1
                    %BC reflexting
                    FC(:)=F(NVh+K,nx,:);
                    FU(:)=F(NVh-K+1,nx,:);
                    FR(:)=FS(NVh+K,nx,:);
                    F_s(NVh+K,nx,:,1)=( (-FR)' .* b);
                    F_ns(NVh+K,nx,:,1)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c')' .* b);
                end
            end % loop for NV
        else
            Fi=reshape(F_new,NV*nx*pp,1);
            [Fn, it_histg, ierr] = nsoli(Fi,'BGKimexL',tol,parms);
            %             [Fn, it_histg, ierr] = brsola(Fi,'BGKimexL',tol,parms);
            F=reshape(Fn,NV,nx,pp);
            for i=1:nx
                Mtemp=zeros(NV,pp);
                for K=1:NV
                    Mtemp(K,:)=F(K,i,:);
                end
                F_loc(:,:)=Mtemp*Pleg;
                for m=1:pp
                    SR(i,:) = wp * F_loc;
                    SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
                    SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
                    SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));
                    
                    R(i,m)    = SR(i,m);
                    U(i,m)    = SU(i,m)/SR(i,m);
                    ET(i,m)   = SE(i,m);
                    AV(i,m)   = SAV(i,m);
                end
            end
            
            if (IT == 0)
                for i=1:nx
                    for m=1:pp
                        T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
                        Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
                        P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                        if T(i,m) <0
                            error('T is Negative')
                        end
                        if P(i,m) <0
                            error('P is Negative')
                        end
                    end
                end
            else
                for i=1:nx
                    for m=1:pp
                        
                        ZA = 0.0001;
                        ZB = 0.99;
                        while (abs(ZA-ZB) > 0.00001)
                            GA12 = 0;
                            GB12 = 0;
                            GA32 = 0;
                            GB32 = 0;
                            for L = 1:50
                                if (IT == 1)
                                    GA12 = GA12 + (ZA^L)*(-1)^(L-1)/(L^0.5);
                                    GB12 = GB12 + (ZB^L)*(-1)^(L-1)/(L^0.5);
                                    GA32 = GA32 + (ZA^L)*(-1)^(L-1)/(L^1.5);
                                    GB32 = GB32 + (ZB^L)*(-1)^(L-1)/(L^1.5);
                                else
                                    GA12 = GA12 + (ZA^L)/(L^0.5);
                                    GB12 = GB12 + (ZB^L)/(L^0.5);
                                    GA32 = GA32 + (ZA^L)/(L^1.5);
                                    GB32 = GB32 + (ZB^L)/(L^1.5);
                                end
                            end
                            PSIA = 2*ET(i,m) - GA32*(R(i,m)/GA12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                            PSIB = 2*ET(i,m) - GB32*(R(i,m)/GB12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                            ZC = (ZA + ZB)/2;
                            GC12 = 0;
                            GC32 = 0;
                            GC52 = 0;
                            for L = 1:50
                                if  (IT == 1)
                                    GC12 = GC12 + (ZC^L)*(-1)^(L-1)/(L^0.5);
                                    GC32 = GC32 + (ZC^L)*(-1)^(L-1)/(L^1.5);
                                    GC52 = GC52 + (ZC^L)*(-1)^(L-1)/(L^2.5);
                                else
                                    GC12 = GC12 + (ZC^L)/(L^0.5);
                                    GC32 = GC32 + (ZC^L)/(L^1.5);
                                    GC52 = GC52 + (ZC^L)/(L^2.5);
                                end
                            end
                            PSIC = 2*ET(i,m) - GC32*(R(i,m)/GC12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                            
                            if ((PSIA*PSIC) < 0)
                                ZB = ZC;
                            else
                                ZA = ZC;
                            end
                        end
                        Z(i,m) = ZC;
                        T(i,m) = R(i,m)^2 / (pi*GC12^2 );
                        P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                        
                    end
                end
            end %if IT
            
            for i = 1:nx
                for K = 1:NV
                    for m=1:pp
                        FEQ(K,i,m)   = 1/((exp( (V(K)-U(i,m))^2 /T(i,m))/Z(i,m)) + IT );
                    end
                end
            end
            for i=1:nx
                for K = 1: NV
                    FC(:)=F(K,i,:);
                    FB(:)=FEQ(K,i,:);
                    FC=(FC'*Pleg-FB')';
                    
                    for j=0:p
                        %         FS(K,i,j+1)=sum (FC'.*Pleg(j+1,:).*w)*(2*j+1)/2/VIS(i,j+1);
                        FS(K,i,j+1)=sum (FC'.*Pleg(j+1,:).*w)*dx/2/VIS(i,j+1);
                    end
                end
                
                
            end
            for K=1:NVh
                if BC_type == 0
                    %BC no-flux
                    FC(:)=F(K,1,:);
                    FU=FC;
                    FR(:)=FS(K,1,:);
                    %F_ns(K,1,:,l)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c'-FR)' .* b);
                    F_s(K,1,:,l)=( (-FR)' .* b);
                    F_ns(K,1,:,l)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c')' .* b);
                elseif BC_type == -1            %BC reflecting
                    FC(:)=F(K,1,:);
                    FU(:)=F(NV-K+1,1,:);
                    FR(:)=FS(K,1,:);
                    %F_ns(K,1,:,l)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c'-FR)' .* b);
                    F_s(K,1,:,l)=( (-FR)' .* b);
                    F_ns(K,1,:,l)=( (V(K)*A'*FC -V(K)* sum(FC)+ V(K)* sum(FU'.* c) * c')' .* b);
                else
                end
                for i=2:nx
                    FU(:)=F(K,i-1,:);
                    FC(:)=F(K,i,:);
                    FR(:)=FS(K,i,:);
                    %F_ns(K,i,:,l)=( (V(K)*A'*FC -V(K)* sum(FC) +V(K)* sum(FU) * c'-FR)' .* b);
                    F_s(K,i,:,l)=( (-FR)' .* b);
                    F_ns(K,i,:,l)=( (V(K)*A'*FC -V(K)* sum(FC) +V(K)* sum(FU) * c')' .* b);
                end
                
                for i=1:nx-1
                    FU(:)=F(NVh+K,i+1,:);
                    FC(:)=F(NVh+K,i,:);
                    FR(:)=FS(NVh+K,i,:);
                    %F_ns(NVh+K,i,:,l)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU'.* c) + V(NVh+K)*sum(FC'.* c) * c'-FR)' .* b);
                    F_s(NVh+K,i,:,l)=( (-FR)' .* b);
                    F_ns(NVh+K,i,:,l)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU'.* c) + V(NVh+K)*sum(FC'.* c) * c')' .* b);
                end
                if BC_type == 0
                    %BC no-flux
                    FC(:)=F(NVh+K,nx,:);
                    FU=FC;
                    FR(:)=FS(NVh+K,nx,:);
                    %F_ns(NVh+K,nx,:,l)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c'-FR)' .* b);
                    F_s(NVh+K,nx,:,l)=( (-FR)' .* b);
                    F_ns(NVh+K,nx,:,l)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c')' .* b);
                elseif BC_type == -1
                    %BC reflexting
                    FC(:)=F(NVh+K,nx,:);
                    FU(:)=F(NVh-K+1,nx,:);
                    FR(:)=FS(NVh+K,nx,:);
                    %F_ns(NVh+K,nx,:,l)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c'-FR)' .* b);
                    F_s(NVh+K,nx,:,l)=( (-FR)' .* b);
                    F_ns(NVh+K,nx,:,l)=( (-V(NVh+K)*A'*(-FC) -V(NVh+K)* sum(FU) +V(NVh+K)* sum(FC'.*c) * c')' .* b);
                end
            end % loop for NV
        end
        
        if l<stage
            F_new=F_new+ dt*const_b(l)*(F_s(:,:,:,l)+F_ns(:,:,:,l));
            F=Fold;
            for j=1:l %u_alt=Un+Xi
                F = F + dt*(const_a_I(l+1,j)*F_s(:,:,:,j) + const_a_E(l+1,j)*F_ns(:,:,:,j));
            end
            
            for i=1:nx
                Mtemp=zeros(NV,pp);
                for K=1:NV
                    Mtemp(K,:)=F(K,i,:);
                end
                F_loc(:,:)=Mtemp*Pleg;
                for m=1:pp
                    SR(i,:) = wp * F_loc;
                    SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
                    SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
                    SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));
                    
                    R(i,m)    = SR(i,m);
                    U(i,m)    = SU(i,m)/SR(i,m);
                    ET(i,m)   = SE(i,m);
                    AV(i,m)   = SAV(i,m);
                end
            end
            
            if (IT == 0)
                for i=1:nx
                    for m=1:pp
                        T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
                        Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
                        P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                        if T(i,m) <0
                            error('T is Negative')
                        end
                        if P(i,m) <0
                            error('P is Negative')
                        end
                    end
                end
            else
                for i=1:nx
                    for m=1:pp
                        
                        ZA = 0.0001;
                        ZB = 0.99;
                        while (abs(ZA-ZB) > 0.00001)
                            GA12 = 0;
                            GB12 = 0;
                            GA32 = 0;
                            GB32 = 0;
                            for L = 1:50
                                if (IT == 1)
                                    GA12 = GA12 + (ZA^L)*(-1)^(L-1)/(L^0.5);
                                    GB12 = GB12 + (ZB^L)*(-1)^(L-1)/(L^0.5);
                                    GA32 = GA32 + (ZA^L)*(-1)^(L-1)/(L^1.5);
                                    GB32 = GB32 + (ZB^L)*(-1)^(L-1)/(L^1.5);
                                else
                                    GA12 = GA12 + (ZA^L)/(L^0.5);
                                    GB12 = GB12 + (ZB^L)/(L^0.5);
                                    GA32 = GA32 + (ZA^L)/(L^1.5);
                                    GB32 = GB32 + (ZB^L)/(L^1.5);
                                end
                            end
                            PSIA = 2*ET(i,m) - GA32*(R(i,m)/GA12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                            PSIB = 2*ET(i,m) - GB32*(R(i,m)/GB12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                            ZC = (ZA + ZB)/2;
                            GC12 = 0;
                            GC32 = 0;
                            GC52 = 0;
                            for L = 1:50
                                if  (IT == 1)
                                    GC12 = GC12 + (ZC^L)*(-1)^(L-1)/(L^0.5);
                                    GC32 = GC32 + (ZC^L)*(-1)^(L-1)/(L^1.5);
                                    GC52 = GC52 + (ZC^L)*(-1)^(L-1)/(L^2.5);
                                else
                                    GC12 = GC12 + (ZC^L)/(L^0.5);
                                    GC32 = GC32 + (ZC^L)/(L^1.5);
                                    GC52 = GC52 + (ZC^L)/(L^2.5);
                                end
                            end
                            PSIC = 2*ET(i,m) - GC32*(R(i,m)/GC12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                            
                            if ((PSIA*PSIC) < 0)
                                ZB = ZC;
                            else
                                ZA = ZC;
                            end
                        end
                        Z(i,m) = ZC;
                        T(i,m) = R(i,m)^2 / (pi*GC12^2 );
                        P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                        
                    end
                end
            end %if IT
            
        else
            F_new=F_new+ dt*const_b(l)*(F_s(:,:,:,l)+F_ns(:,:,:,l));
            
        end
    end % RK
    F=F_new;
    for i=1:nx
        Mtemp=zeros(NV,pp);
        for K=1:NV
            Mtemp(K,:)=F(K,i,:);
        end
        F_loc(:,:)=Mtemp*Pleg;
        for m=1:pp
            SR(i,:) = wp * F_loc;
            SU(i,m) = sum(wp.*F_loc(:,m)'.* V);
            SE(i,m) = sum(wp.*F_loc(:,m)'.* V.^2)/2;
            SAV(i,m)= sum(wp.*F_loc(:,m)'.* abs(V));
            
            R(i,m)    = SR(i,m);
            U(i,m)    = SU(i,m)/SR(i,m);
            ET(i,m)   = SE(i,m);
            AV(i,m)   = SAV(i,m);
        end
    end
    
    if (IT == 0)
        for i=1:nx
            for m=1:pp
                T(i,m)    = 4*ET(i,m)/R(i,m) - 2*U(i,m)^2;
                Z(i,m)    = R(i,m) / sqrt(pi* T(i,m));
                P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
                if T(i,m) <0
                    error('T is Negative')
                end
                if P(i,m) <0
                            error('P is Negative')
                        end
            end
        end
    else
        for i=1:nx
            for m=1:pp
                ZA = 0.0001;
                ZB = 0.99;
                while (abs(ZA-ZB) > 0.00001)
                    GA12 = 0;
                    GB12 = 0;
                    GA32 = 0;
                    GB32 = 0;
                    for L = 1:50
                        if (IT == 1)
                            GA12 = GA12 + (ZA^L)*(-1)^(L-1)/(L^0.5);
                            GB12 = GB12 + (ZB^L)*(-1)^(L-1)/(L^0.5);
                            GA32 = GA32 + (ZA^L)*(-1)^(L-1)/(L^1.5);
                            GB32 = GB32 + (ZB^L)*(-1)^(L-1)/(L^1.5);
                        else
                            GA12 = GA12 + (ZA^L)/(L^0.5);
                            GB12 = GB12 + (ZB^L)/(L^0.5);
                            GA32 = GA32 + (ZA^L)/(L^1.5);
                            GB32 = GB32 + (ZB^L)/(L^1.5);
                        end
                    end
                    PSIA = 2*ET(i,m) - GA32*(R(i,m)/GA12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                    PSIB = 2*ET(i,m) - GB32*(R(i,m)/GB12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                    ZC = (ZA + ZB)/2;
                    GC12 = 0;
                    GC32 = 0;
                    GC52 = 0;
                    for L = 1:50
                        if  (IT == 1)
                            GC12 = GC12 + (ZC^L)*(-1)^(L-1)/(L^0.5);
                            GC32 = GC32 + (ZC^L)*(-1)^(L-1)/(L^1.5);
                            GC52 = GC52 + (ZC^L)*(-1)^(L-1)/(L^2.5);
                        else
                            GC12 = GC12 + (ZC^L)/(L^0.5);
                            GC32 = GC32 + (ZC^L)/(L^1.5);
                            GC52 = GC52 + (ZC^L)/(L^2.5);
                        end
                    end
                    PSIC = 2*ET(i,m) - GC32*(R(i,m)/GC12)^3/(2*pi) - R(i,m)*U(i,m)^2;
                    
                    if ((PSIA*PSIC) < 0)
                        ZB = ZC;
                    else
                        ZA = ZC;
                    end
                end
                Z(i,m) = ZC;
                T(i,m) = R(i,m)^2 / (pi*GC12^2 );
                P(i,m) = ET(i,m) - 0.5 * R(i,m) * U(i,m)^2;
            end
        end
    end %if IT
    
    r_plot=reshape(R',nx*pp,1);
    u_plot=reshape(U',nx*pp,1);
    et_plot=reshape(ET',nx*pp,1);
    p_plot=reshape(P',nx*pp,1);
    t_plot=reshape(T',nx*pp,1);
    z_plot=reshape(Z',nx*pp,1);
    if bb==1
        set(wave_handleu,'YData',u_plot);
        set(wave_handler,'YData',r_plot);
        set(wave_handleet,'YData',et_plot);
        set(wave_handleav,'YData',p_plot);
        set(wave_handlet,'YData',t_plot);
        set(wave_handlez,'YData',z_plot);
        drawnow
    end
    %fprintf('1X ELAPSED TIME: %f7.4,4 DENSITY AT X=4.0,Y=5.: %f7.4\n', TIME, R(NXP1/2))
    ITER = ITER + 1;
end
toc


