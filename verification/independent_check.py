# Independent recomputation of the headline numbers of the reference dataset with NumPy/SciPy only
# (values typed in from data/raw/reference/*.csv; no code shared with the R pipeline).
#   python3 verification/independent_check.py
# The output is kept in verification/independent_check_output.txt for comparison with data/processed/report_values.csv.
import numpy as np, csv
from scipy.optimize import curve_fit, least_squares
# --- standard curve ---
std = [(0.0833333,0.428),(0.1666667,0.856),(0.25,1.240),(0.3333333,1.723),(0.4333333,2.256),(0.5333333,3.236)]
x=np.array([s[0] for s in std[:5]]); y=np.array([s[1] for s in std[:5]])
A=np.vstack([x,np.ones_like(x)]).T; (eps,icpt),res,_,_=np.linalg.lstsq(A,y,rcond=None)
yhat=eps*x+icpt; r2=1-((y-yhat)**2).sum()/((y-y.mean())**2).sum()
n=len(x); se=np.sqrt(((y-yhat)**2).sum()/(n-2)/((x-x.mean())**2).sum())
print(f"epsilon = {eps:.4f} +/- {se:.4f}, intercept {icpt:.4f}, R2 {r2:.5f}; through-origin {np.sum(x*y)/np.sum(x*x):.4f}")
pred6=eps*std[5][0]+icpt; print(f"6th standard predicted {pred6:.3f} vs observed {std[5][1]} ({100*(std[5][1]-pred6)/pred6:+.1f}%)")
# all 6 standards / with zero
x6=np.array([s[0] for s in std]); y6=np.array([s[1] for s in std]); print("eps all 6 standards:", np.polyfit(x6,y6,1))
x7=np.r_[0,x]; y7=np.r_[0,y]; print("eps 5 standards + zero point:", np.polyfit(x7,y7,1))
# --- V0 rule ---
t=np.array([2,4,6,8,10.])
d2 = {('noI','A'):[0.282,0.546,0.815,1.094,1.328],('noI','B'):[0.202,0.383,0.516,0.628,0.723],('noI','C'):[0.156,0.278,0.357,0.425,0.468],
 ('noI','D'):[0.11,0.172,0.211,0.24,0.301],('noI','E'):[0.116,0.148,0.166,0.171,0.18],('noI','F'):[0.047,0.067,0.077,0.084,0.09],
 ('I','A'):[0.198,0.48,0.586,0.784,0.966],('I','B'):[0.065,0.127,0.196,0.239,0.294],('I','C'):[0.045,0.086,0.128,0.154,0.187],
 ('I','D'):[0.029,0.051,0.068,0.085,0.099],('I','E'):[0.02,0.035,0.047,0.06,0.069],('I','F'):[0.011,0.019,0.025,0.031,0.036]}
REL,ABS=0.20,0.010
def tol(p): return max(REL*p,ABS)
def rule(a):
    a=np.array(a); inc=np.diff(a)
    curved=(inc[0]-inc[1]>tol(inc[0])) and (inc[0]-inc[2]>tol(inc[0]))
    if curved: return a[0]/2.0,'secant0-2',None
    k=3
    while k<5:
        b=np.polyfit(t[:k],a[:k],1); pred=b[0]*2; obs=a[k]-a[k-1]
        if abs(obs-pred)<=tol(pred): k+=1
        else: break
    b=np.polyfit(t[:k],a[:k],1); return b[0],f'reg2-{int(t[k-1])}',b[1]
S=np.array([2.2,1.1,0.55,0.275,0.1375,0.06875]); conv=1/eps*1.5*12
V={}
for cond in ['noI','I']:
    V[cond]=np.array([rule(d2[(cond,tb)])[0] for tb in 'ABCDEF'])
    print(cond, [f"{tb}:{rule(d2[(cond,tb)])[0]:.4f}({rule(d2[(cond,tb)])[1]})" for tb in 'ABCDEF'])
print(f"conversion factor umol/min per dA/min = {conv:.4f}")
def LB(S,V):
    b=np.polyfit(1/S,1/V,1); Vmax=1/b[1]; Km=b[0]*Vmax
    yh=np.polyval(b,1/S); r2=1-((1/V-yh)**2).sum()/((1/V-(1/V).mean())**2).sum()
    # intercept SE
    xx=1/S; n=len(xx); s2=((1/V-yh)**2).sum()/(n-2); se_b=np.sqrt(s2*(1/n+xx.mean()**2/((xx-xx.mean())**2).sum()))
    from scipy.stats import t as tdist
    p=2*(1-tdist.cdf(abs(b[1]/se_b),n-2))
    return Km,Vmax,b[0],b[1],r2,se_b,p
for cond in ['noI','I']:
    Km,Vmax,sl,ic,r2,seb,p=LB(S,V[cond]*conv)
    print(f"LB {cond}: Km {Km:.4f} Vmax {Vmax:.4f} slope {sl:.4f} intercept {ic:.4f} (SE {seb:.3f}, p {p:.3f}) R2 {r2:.4f}")
Km0,Vm0=LB(S,V['noI']*conv)[:2]; Kma=LB(S,V['I']*conv)[0]; print(f"Ki (competitive eq) = {0.458333/(Kma/Km0-1):.4f}")
mm=lambda S,Vmax,Km: Vmax*S/(Km+S)
popt,pcov=curve_fit(mm,S,V['noI']*conv,p0=[0.5,0.3]); print("NLS noI:", popt, np.sqrt(np.diag(pcov)))
try:
    popt2,pcov2=curve_fit(mm,S,V['I']*conv,p0=[0.5,2],bounds=([0,0],[50,100]),maxfev=10000); print("NLS +I:", popt2, np.sqrt(np.diag(pcov2)))
except Exception as e: print("NLS +I failed", e)
# global competitive
Sg=np.r_[S,S]; Ig=np.r_[np.zeros(6),np.full(6,0.4583333)]; Vg=np.r_[V['noI'],V['I']]*conv
comp=lambda X,Vmax,Km,Ki: Vmax*X[0]/(Km*(1+X[1]/Ki)+X[0])
pc,cc=curve_fit(comp,(Sg,Ig),Vg,p0=[0.5,0.4,0.1]); rss=((Vg-comp((Sg,Ig),*pc))**2).sum()
aic=12*np.log(rss/12)+2*4  # k=3 params + sigma
print("global competitive:", pc, np.sqrt(np.diag(cc)), "RSS", rss, "AIC(k=4)", aic)
mixed=lambda X,Vmax,Km,Ki,Kip: Vmax*X[0]/(Km*(1+X[1]/Ki)+X[0]*(1+X[1]/Kip))
pm,cm=curve_fit(mixed,(Sg,Ig),Vg,p0=[0.5,0.4,0.1,5],bounds=([0,0,0,0],[50,100,50,500]),maxfev=20000); rssm=((Vg-mixed((Sg,Ig),*pm))**2).sum()
print("global mixed:", pm, "RSS", rssm, "AIC(k=5)", 12*np.log(rssm/12)+2*5)
# noncompetitive global: V = Vmax S / ((Km+S)(1+I/Ki))
nonc=lambda X,Vmax,Km,Ki: Vmax*X[0]/((Km+X[0])*(1+X[1]/Ki))
pn,cn=curve_fit(nonc,(Sg,Ig),Vg,p0=[0.5,0.4,0.3]); rssn=((Vg-nonc((Sg,Ig),*pn))**2).sum()
print("global noncompetitive:", pn, np.sqrt(np.diag(cn)), "RSS", rssn, "AIC(k=4)", 12*np.log(rssn/12)+2*4)
# independent Vmax per condition model (two separate MM, shared nothing): compare RSS
rss_sep=((V['noI']*conv-mm(S,*popt))**2).sum()
print("separate uninhibited MM RSS", rss_sep)
