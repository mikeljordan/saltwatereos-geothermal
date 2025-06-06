%module H2O
%{
    // #define SWIG_FILE_WITH_INIT
    #include "H2O.H"
%}

%include std_string.i
%include std_vector.i
// ===== This is required for python API but js seems doesn't need it========
namespace std {
   %template(IntVector) vector<int>;
   %template(DoubleVector) vector<double>;
   %template(StringVector) vector<string>;
   %template(ConstCharVector) vector<const char*>;
}
// ========================================================================
%inline %{
using namespace std;
%}
%include "typemaps.i"
%apply std::vector<double> *OUTPUT {std::vector<double>& p_boiling};

namespace H2O
{
    /**
     * @brief Table 6.2 of reference \cite wagner2002iapws.
     * 
     */
    struct Table62
    {
        static const unsigned int numCoeff = 56;
        double c[numCoeff], d[numCoeff], t[numCoeff], n[numCoeff];
        double alpha[numCoeff], beta[numCoeff], gamma[numCoeff], epsilon[numCoeff], a[numCoeff], b[numCoeff], A[numCoeff], B[numCoeff], C[numCoeff], D[numCoeff];
    };
    /**
     * @brief Table 6.1 of \cite wagner2002iapws.
     * 
     */
    struct Table61
    {
        double n0[8]={-8.32044648201, 6.6832105268, 3.00632, 0.012436, 0.97315, 1.2795, 0.96956, 0.24873};
        double gamma0[8]={0, 0, 0, 1.28728967, 3.53734222, 7.74073708, 9.24437796, 27.5075105};
    };
    // ============= Constants of H2O ========================================================================
    double const PMIN = 1E5; /**< Minimum valid pressure of H2O, [Pa]. IAPWS-95 */ 
    double const PMAX = 10000E5; /**< Minimum valid pressure of H2O, [Pa]. IAPWS-95 */ 
    double const TMIN = 0.1; /**< Minimum valid pressure of H2O, [\f$ ^{\circ}\text{C} \f$]. IAPWS-95 */ 
    double const TMAX = 1000; /**< Minimum valid pressure of H2O, [\f$ ^{\circ}\text{C} \f$]. IAPWS-95 */ 
    // double const P_Critic_MPa = 22.064; /**< Pressure at critical point of H2O, [MPa]. IAPWS-95 */
    double const T_Critic_K = 647.096; /**< Temperature at critical point of H2O, [K]. IAPWS-95 */ 
    double const P_Critic = 220.64; /**< Pressure at critical point of H2O, [bar]. IAPWS-95 */
    double const T_Critic = T_Critic_K - Kelvin; /**< Temperature at critical point of H2O, [\f$^{\circ}\text{C} \f$]. IAPWS-95 */ 
    double const Rho_Critic = 322; /**< Critical density, [\f$ kg \ m^{-3} \f$]. IAPWS-95 */ 

    double const MolarMass = 0.018015; /**< molar mass of water  [kg/mol] */

    double const T_Triple_K = 273.16; /**< [K] */
    double const T_Triple = 273.16 - Kelvin; /**< [\f$^{\circ}\text{C} \f$] */
    double const P_Triple = 611.655E-5; /**< Pressure at triple point of H2O, [bar]. IAPWS-95 */
    double const Rho_Triple_liquid = 999.793; /**< Liquid density at triple point, [\f$ kg \ m^{-3} \f$]. IAPWS-95 */ 
    double const Rho_Triple_vapor = 0.00485458; /**< Vapor density at triple point, [\f$ kg \ m^{-3} \f$]. IAPWS-95 */ 

    enum PhaseRegion {iceI, iceIII, iceV, iceVI, iceVII};
    double const T_K_ice_min[5]={251.165, 251.165, 256.164, 273.31, 355};
    double const T_K_ice_max[5]={T_Triple_K, 256.164, 273.31, 355, 715};

    double const R_const = 0.46151805; /**< Specific gas constant [\f$ kJ kg^{-1} K^{-1} \f$] */
    // =======================================================================================================

    /**
     * @brief Water EOS and properties implementation. 
     * 
     * This implementation is based on public libraries, e.g. <a href="http://freesteam.sourceforge.net">Freesteam 2.0</a>,  <a href="http://fluidos.etsii.upm.es/faculty/Jaime_Carpio/Fumatas_negas/PROST%20Properties%20of%20Water%20and%20Steam.htm">PROST</a>, and published references \cite huber2009new, \cite wagner2002iapws, \cite Klyukin2020. 
     * 
     * The formulation is valid in the entire stable fluid region from the melting curve to 1273 K at pressures to 1000 MPa. It extrapolates in a physically reasonable way outside this region. See also <a href="http://www.iapws.org/relguide/IAPWS-95.html">IAPWS95</a>.
     * 
     */
    class cH2O// : public Fluid::cFluid
    {
    private:
        Table62 m_Table62;
        Table61 m_Table61;
        void LoadTable62(Table62& m_Table62);
        bool m_isHighAccuracy;
    public:
        cH2O(/* args */);
        ~cH2O();
        /**
         * @brief Temperature-pressure relations on boiling curve of water. See equation (2.5) of reference \cite wagner2002iapws.
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @return double Pressure [bar]
         */
        double P_Boiling(double T);
        double T_Boiling(double P);
        /**
         * @brief Saturated liquid density. See equation (2.6) of reference \cite wagner2002iapws. 
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @return double Density [\f$ kg\ m^{-3} \f$]
         */
        double Rho_Liquid_Saturated(double T);
        /**
         * @brief Saturated vapor density. See equation (2.7) of reference \cite wagner2002iapws. 
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @return double Density [\f$ kg\ m^{-3} \f$]
         */
        double Rho_Vapor_Saturated(double T);
        /**
         * @brief Water density as a function of T and P.
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @param P Pressure [\f$ bar \f$]
         * @return double Density [\f$ kg\ m^{-3} \f$]
         */
        double Rho(double T, double P);
        /**
         * @brief Derivative of the residual part \f$ \phi^r \f$ of the dimensionless Helmholtz free energy. See Table 6.5 of the reference \cite wagner2002iapws.
         * 
         * \f$ \phi^{r}_{\delta} = \left[ \frac{\partial \phi^r}{\partial \delta} \right]_{\tau} \f$.  
         * \f$ \phi^r\f$  is defined in equation 6.6 of \cite wagner2002iapws, where \f$ \delta, \tau \f$ are defined in equation 6.4 of \cite wagner2002iapws.
         * 
         * @param delta \f$ \delta = \frac{\rho}{\rho_c} \f$
         * @param tau \f$ \tau = \frac{T_c}{T} \f$
         * @return double 
         */
        double Phi_r_delta(double delta, double tau);
        /**
         * @brief See Table 6.3 of\cite wagner2002iapws. 
         * 
         * \f$ \phi^{0}_{\tau} = \left[ \frac{\partial \phi^0}{\partial \tau} \right]_{\delta} \f$.  
         * \f$ \phi^0\f$  is defined in equation 6.5 of \cite wagner2002iapws.
         * 
         * Where \f$ \delta, \tau \f$ are defined in equation 6.4 of \cite wagner2002iapws.
         * 
         * @param delta \f$ \delta =  \rho / \rho_c\f$
         * @param tau \f$ \tau = T_c / T\f$, unit of \f$ T, T_c \f$ is K.
         * @return double 
         */
        double Phi_o_tau(double delta, double tau);
        /**
         * @brief See Table 6.3 of\cite wagner2002iapws. 
         * 
         * \f$ \phi^{r}_{\tau} = \left[ \frac{\partial \phi^r}{\partial \tau} \right]_{\delta} \f$.  
         * \f$ \phi^r\f$  is defined in equation 6.6 of \cite wagner2002iapws.
         * 
         * Where \f$ \delta, \tau \f$ are defined in equation 6.4 of \cite wagner2002iapws.
         * 
         * @param delta \f$ \delta =  \rho / \rho_c\f$
         * @param tau \f$ \tau = T_c / T\f$, unit of \f$ T, T_c \f$ is K.
         * @return double 
         */
        double Phi_r_tau(double delta, double tau);

        /**
         * @brief Calculate pressure given temperature and density. See equation in Table 6.3 of reference \cite wagner2002iapws.
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @param Rho Density [\f$ kg\ m^{-3} \f$]
         * @return double Pressure [bar]
         */
        double Pressure_T_Rho(double T, double Rho);
        /**
         * @brief Sublimation-Pressure. \b Solid-Vapor phase boundary. The valid temperature region is \f$[T_{min}, T_{triple}] \f$. See equation (2.21) of reference \cite wagner2002iapws.
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @return double Pressure [bar]
         */
        double SublimationCurve(double T);
        /**
         * @brief \b Liquid-Vapor phase boundary. Calculate pressure based saturated vapor density #Rho_Vapor_Saturated  and relations between pressure, density and temperautre #Pressure_T_Rho. The valid temperature region is \f$[T_{triple}, T_{critic}] \f$.
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @return double Pressure [bar]
         */
        double BoilingCurve(double T);
        void BoilingCurve(std::vector<double> T, std::vector<double>& p_boiling);
        /**
         * @brief Melting-Pressure. \b Solid-Liquid phase boundary. See equation (2.16) of reference \cite wagner2002iapws.
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @return double Pressure [bar]
         */
        double MeltingCurve(double T, bool isIceI=false);
        
        /**
         * @brief Specific enthalpy as a function of temperature and density.
         * See Table 6.3 of \cite wagner2002iapws.
         * 
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @param Rho Density [\f$ kg/m^3 \f$]
         * @return Specific enthalpy [\f$ J/kg \f$]
         */
        double SpecificEnthalpy_T_Rho(double T, double Rho);
        /**
         * @brief 
         * 
         * @param T Temperature [\f$ ^{\circ}\text{C} \f$]
         * @param P Pressure [\f$ bar \f$]
         * @return Specific enthalpy [\f$ J/kg \f$] 
         */
        double SpecificEnthalpy(double T, double P);
    public:
        
    };
    
}
