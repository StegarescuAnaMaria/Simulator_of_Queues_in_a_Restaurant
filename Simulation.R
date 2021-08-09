library(shiny)
library(shinythemes)

# Functia de intensitate a procesului Poisson
lambda <- function(t)
{
  if (t <= 4)
    return(3*t^2 + 2*t +1)

  else if (t < 5 && t > 4)
    return(2*exp(t) - 1)

  else if (t <= 10 && t >= 5)
    return(log(t) + 5*t)

  else if (t < 11 && t > 10)
    return(cos(t)*exp(-2*t) +2)
  else
    return(2*t +5)
}


valori <- c(0.5, 0.8, 1.2, 1.8, 2)
prob <- c(1/4, 1/2, 1/12, 1/24, 3/24)

# Functia cumsum calculeaza sumele partiale ale elementelor unui vector
sum_part <- cumsum(prob)

genereaza_Y1 <- function()
{
  U <- runif(1)
  
  # Functia which returneaza un vector de indici ce satisfac o anumita conditie
  i <- which.max(U<sum_part)
  
  x <- valori[i]
  
  return(x/60)
}


Exp <- function()   #Exp lambda = 1
{
  U <- runif(1)
  return(-log(U))
}


#Simulam Norma(15, 2) prin metoda respingerii cu ajutorul exponentialei de lambda 1
# Am calculat c=2

Norm <- function()
{
  U2 <- runif(1)
  miu <- 15
  while(TRUE)
  {
    Y <- Exp()
    raport <- 1/(2*sqrt(pi))*exp(Y - 1/4*Y^2)
    U1 <- runif(1)
    if(U1<=raport)
    {
      X_modul <- Y
      break
    }
  }
  if(U2<=1/2)
  {
    X <- miu - X_modul 
  }
  else
  {
    X <- miu + X_modul
  }
  return(X/60)
}


pret <- function(t)
{
  5*t^2 + 90*abs(t)
}



# Functie care genereaza Ts (momentul primei sosiri dupa momentul s)
genereaza_Ts <- function(s)
{
  t <- s
  while(1)
  {
    U1 <- runif(1)
    U2 <- runif(1)
    # Constanta lambda pt care lambda(t) <= lambda_const pt orice t>0
    if (t <= 4)
      lambda_constant <- 57

    else if (t < 5 && t > 4)
      lambda_constant <- 296

    else if (t <= 10 && t >= 5)
      lambda_constant <- 53

    else if (t < 11 && t > 10)
      lambda_constant <- 2
    else
      lambda_constant <- 31
    
    t <- t - 1/lambda_constant * log(U1)

    if(U2 <= lambda(t)/lambda_constant)
    {
      Ts <- t
      return(Ts)
    }
  }
}


schema_simulare <- function(client_max1=10, client_max2=15, T_max=12, t=0)
{
  # Initializari
  Na <- 0
  Nd <- 0
  n1 <- 0
  n2 <- 0
  T0 <- genereaza_Ts(0)
  
  tA <- T0
  t1 <- Inf
  t2 <- Inf
  A1 <- c(Inf)
  A2 <- c(Inf)
  D <- c(Inf)
  venit <- c(Inf)
  clienti_pierduti1 <- c()
  clienti_pierduti2 <- c()
  
  
  while(tA <= T_max)
  {
    
    # Cazul 1 - soseste un client nou la serverul 1
    if(tA == min(c(tA,t1,t2)))
    {
      t <- tA
      if(n1<client_max1)
      {
        Na <- Na + 1
        n1 <- n1 + 1
        Tt <- genereaza_Ts(t)
        tA <- Tt
        if(length(A1)<Na)
        {
          A1 <- c(A1, Inf)
          A2 <- c(A2, Inf)
          D <- c(D, Inf) 
          venit <- c(venit, Inf)
        }
                                 # marim dim vectorilor pentru urmatorul client
        
        
        # Clientul care tocmai ce a sosit va fi servit imediat de serverul 1
        if(n1 == 1)
        {
          # Generam timpul de servire
          y1 <- genereaza_Y1()
          
          t1 <- t+y1
        }
        A1[Na] <- t
      }
      else
      {
        clienti_pierduti1 <- c(clienti_pierduti1, t)
        Tt <- genereaza_Ts(t)                   #generam tA pentru urmatorul client
        tA <- Tt
      }
    }
    
    # Cazul 2 - serverul 1 se elibereaza inaintea sosirii unui client nou
    if(t1 < tA && t1 <= t2)
    {
      t <- t1
      if(n2<client_max2)
      {
        n1 <- n1 - 1
        n2 <- n2 + 1
        
        if(n1 == 0)
        {
          t1 <- Inf
        }
        else
        {
          # Generam timpul de servire
          y1 <- genereaza_Y1()
          
          t1 <- t+y1
        }
        
        if(n2 == 1)
        {
          # Generam timpul de servire
          y2 <- Norm()
          t2 <- t + y2
          venit[Na-n1] <- pret(y2)
        }
        A2[Na-n1] <- t
      }
      else
      {
        clienti_pierduti2 <- c(clienti_pierduti2, t)
        venit[Nd+n2+1] <- Inf
        n1 <- n1 - 1      #clientul pleaca din coada 1
        Na <- Na - 1        #clienti deserviti
        if(n1 == 0)
        {
          t1 <- Inf
        }
        else
        {
          # Generam timpul de servire
          y1 <- genereaza_Y1()
          
          t1 <- t + y1
        }
      }
    }
    
    # Cazul 3 - serverul 2 se elibereaza inainte de a sosi un client nou si inainte de finalizarea 
    # activitatii la serverul 1
    if(t2<t1 && t2<tA)
    { 
      t <- t2
      Nd <- Nd + 1
      n2 <- n2 - 1
      
      if(n2 == 0)
      {
        t2 <- Inf
      }
      if(n2 >= 1)
      {
        # Generam timpul de servire
        y2 <- Norm()
        
        t2 <- t+y2
        venit[Nd+1] <- pret(y2)
      }
      D[Nd] <- t
    }
  }                         #daca mai avem clienti in una dintre cozi, prelungim orarul de munca
    while(n1!=0 || n2!=0)
    {
      #nu mai sosesc clienti noi la coada 1, am scos cazul 1

      # Cazul 2 - serverul 1 se elibereaza inaintea sosirii unui client nou
      if(t1 <= t2)
      {
        t <- t1
        if(n2<client_max2)
        {
          n1 <- n1 - 1
          n2 <- n2 + 1
          
          if(n1 == 0)
          {
            t1 <- Inf
          }
          else
          {
            # Generam timpul de servire
            y1 <- genereaza_Y1()
            
            t1 <- t+y1
          }
          
          if(n2 == 1)
          {
            # Generam timpul de servire
            y2 <- Norm()
            
            t2 <- t + y2
            venit[Na-n1] <- pret(y2)
          }
          A2[Na-n1] <- t
        }
        else
        {
          clienti_pierduti2 <- c(clienti_pierduti2, t)
          venit[Nd+n2+1] <- -1
          Na <- Na - 1
          n1 <- n1 - 1      #clientul pleaca din coada 1
          if(n1 == 0)
          {
            t1 <- Inf
          }
          else
          {
            # Generam timpul de servire
            y1 <- genereaza_Y1()
            
            t1 <- t+y1
          }
        }
      }

      # Cazul 3 - serverul 2 se elibereaza inainte de a sosi un client nou si inainte de finalizarea activitatii la serverul 1
      if(t2 < t1)
      {
        t <- t2
        Nd <- Nd + 1
        n2 <- n2 - 1

        if(n2 == 0)
        {
          t2 <- Inf
        }
        if(n2 >= 1)
        {
          # Generam timpul de servire
          y2 <- Norm()

          t2 <- t+y2
          venit[Nd+1] <- pret(y2)
        }
        D[Nd] <- t
      }
    }
  i <- length(A2)
  while(A2[i] == Inf)
  {
    i <- i-1
  }
   
   A1 <- A1[1:i]
   A2 <- A2[1:i]
   D <- D[1:i]
   venit <- venit[1:i]

  return(list(A1, A2, D, venit, clienti_pierduti1, clienti_pierduti2))
}


rezultat <- schema_simulare()


#Primul moment de timp la care se pierde un client
print("Primul moment de timp la care se pierde un client")
t_pierdut <- min(min(rezultat[[5]]), min(rezultat[[6]]))
print(t_pierdut)

timp_clienti_pierduti_1 <- rezultat[[5]]
timp_clienti_pierduti_2 <- rezultat[[6]]
timp_clienti_pierduti <- union(timp_clienti_pierduti_1,timp_clienti_pierduti_2)

A1 <- rezultat[[1]]
A2 <- rezultat[[2]]
venit <- rezultat[[4]]


#Timpii petrecuti in ambele cozi si total pe timpul zilei
timp_c1 <- rezultat[[2]] - rezultat[[1]]
timp_c2 <- rezultat[[3]] - rezultat[[2]]
timp_t <- rezultat[[3]] - rezultat[[1]]

#Timpul minim petrecut de un client in coada 1
print("Timpul minim petrecut de un client in coada 1")
print(min(timp_c1))


#Timpul minim petrecut de un client in coada 2
print("Timpul minim petrecut de un client in coada 2")
print(min(timp_c2))

#Timpul minim petrecut de un client in sistem
print("Timpul minim petrecut de un client in sistem")
print(min(timp_t))

#Timpul maxim petrecut de un client in coada 1
print("Timpul maxim petrecut de un client in coada 1")
print(max(timp_c1))

#Timpul maxim petrecut de un client in coada 2
print("Timpul maxim petrecut de un client in coada 2")
print(max(timp_c2))

#Timpul maxim petrecut de un client in sistem
print("Timpul maxim petrecut de un client in sistem")
print(max(timp_t))

#Timpul mediu petrecut de un client in coada 1
print("Timpul mediu petrecut de un client in coada 1")
print(sum(timp_c1)/length(timp_c1))

#Timpul mediu petrecut de un client in coada 2
print("Timpul mediu petrecut de un client in coada 2")
print(sum(timp_c2)/length(timp_c2))

#Timpul mediu petrecut de un client in sistem
print("Timpul mediu petrecut de un client in sistem")
print(sum(timp_t)/length(timp_t))



n <- 10^3
n_clients <- c()
n_pierduti1 <- c()
n_pierduti2 <- c()
n_pierduti_t <- c()
castig_zi <- c()
for(val in 1:n)
{
  rezultat <- schema_simulare()
  
  n_pierduti2 <- c(n_pierduti2, length(rezultat[[6]]))
  
  n_pierduti1 <- c(n_pierduti1, length(rezultat[[5]]))
  
  n_pierduti_t <- c(n_pierduti_t, n_pierduti2[length(n_pierduti2)] + n_pierduti1[length(n_pierduti1)])

  n_clients <- c(n_clients, length(rezultat[[2]]))
  castig_zi <- c(castig_zi, sum(rezultat[[4]]))
  
}

print("Numarul mediu de clienti deserviti intr-o zi")
print(sum(n_clients)/length(n_clients))

print("Numarul mediu de clienti pierduti in coada 1")
print(sum(n_pierduti1)/length(n_pierduti1))

print("Numarul mediu de clienti pierduti in coada 2")
print(sum(n_pierduti2)/length(n_pierduti2))

print("Numarul mediu de clienti pierduti")
print(sum(n_pierduti_t)/length(n_pierduti_t))

print("Castigul mediu zilnic")
castig_mediu_zilnic <- sum(castig_zi)/length(castig_zi)
print(castig_mediu_zilnic)

print("Castigul minim zilnic in 1000 zile")
castig_minim_zilnic <- min(castig_zi)
print(castig_minim_zilnic)

print("Castigul maxim zilnic in 1000 zile")
castig_maxim_zilnic <- max(castig_zi)
print(castig_maxim_zilnic)


#Inceperea programului cu o ora mai devreme
castig_zi <- c()
for(val in 1:n)
{
  rezultat <- schema_simulare(client_max1=10, client_max2=15, T_max=12, t=-1)
  castig_zi <- c(castig_zi, sum(rezultat[[4]]))
}

print("Castigul mediu zilnic daca programul incepe cu o ora mai devreme")
castig_mediu_zilnic_o_ora_mai_devreme <- sum(castig_zi)/length(castig_zi)
print(castig_mediu_zilnic_o_ora_mai_devreme)

diferenta_castig_1 <- castig_mediu_zilnic_o_ora_mai_devreme - castig_mediu_zilnic
print("Diferenta de castig fata de programul obisnuit")
print(diferenta_castig_1)


#Inceperea programului cu o ora mai tarziu
castig_zi <- c()
for(val in 1:n)
{
  rezultat <- schema_simulare(client_max1=10, client_max2=15, T_max=13, t=0)
  castig_zi <- c(castig_zi, sum(rezultat[[4]]))
}

print("Castigul mediu zilnic daca programul incepe cu o ora mai tarziu")
castig_mediu_zilnic_o_ora_mai_tarziu <- sum(castig_zi)/length(castig_zi)
print(castig_mediu_zilnic_o_ora_mai_tarziu)


diferenta_castig_2 <- castig_mediu_zilnic_o_ora_mai_tarziu - castig_mediu_zilnic
print("Diferenta de castig fata de programul obisnuit")
print(diferenta_castig_2)


#Prelungirea cozii 1 de asteptare
castig_zi <- c()
for(val in 1:n)
{
  rezultat <- schema_simulare(client_max1=15, client_max2=15, T_max=12, t=0)
  castig_zi <- c(castig_zi, sum(rezultat[[4]]))
}

print("Castigul mediu zilnic daca putem avea cu 5 clienti mai multi in prima coada")
castig_mediu_plus5_1 <- sum(castig_zi)/length(castig_zi)
print(castig_mediu_plus5_1)

print("Diferenta de castig fata de programul obisnuit")
diferenta_castig_plus5_1 <- castig_mediu_plus5_1 - castig_mediu_zilnic
print(diferenta_castig_plus5_1)


#Prelungirea cozii 2 de asteptare
castig_zi <- c()
for(val in 1:n)
{
  rezultat <- schema_simulare(client_max1=10, client_max2=20, T_max=12, t=0)
  castig_zi <- c(castig_zi, sum(rezultat[[4]]))
}

print("Castigul mediu zilnic daca putem avea cu 5 clienti mai multi in a doua coada")
castig_mediu_plus5_2 <- sum(castig_zi)/length(castig_zi)
print(castig_mediu_plus5_2)

print("Diferenta de castig fata de programul obisnuit")
diferenta_castig_plus5_2 <- castig_mediu_plus5_2 - castig_mediu_zilnic
print(diferenta_castig_plus5_2)

ui <- fluidPage(theme = shinytheme("cerulean"),
  titlePanel("Sistem de tip coada cu doua servere legate in serie"),
  navbarPage("Meniu",
   tabPanel(icon("home"),
            fluidRow(column(width=2),
                     column(
                       h4(p("Rezultate obtinute",style="color:black;text-align:center")),
                       width=8,style="background-color:lavender;border-radius: 10px")
            ),
            br(),
            fluidRow(column(width=2, icon("hand-point-right","fa-5x"),align="center"),
                     column(
                       p("Timpul minim petrecut de un client in coada 1: ",min(timp_c1)*60, " minute;",style="color:black;text-align:justify;margin-top:8px"),
                       p("Timpul minim petrecut de un client in coada 2: ",min(timp_c2)*60, " minute;",style="color:black;text-align:justify"),
                       p("Timpul minim petrecut de un client in sistem: ",min(timp_t)*60, " minute;",style="color:black;text-align:justify"),
                       p("Timpul maxim petrecut de un client in coada 1: ",max(timp_c1), " ore;",style="color:black;text-align:justify"),
                       p("Timpul maxim petrecut de un client in coada 2: ",max(timp_c2), " ore;",style="color:black;text-align:justify"),
                       p("Timpul maxim petrecut de un client in sistem: ",max(timp_t), " ore;",style="color:black;text-align:justify"),
                       p("Timpul mediu petrecut de un client in coada 1: ",sum(timp_c1)/length(timp_c1)*60, " minute;",style="color:black;text-align:justify"),
                       p("Timpul mediu petrecut de un client in coada 2: ",sum(timp_c2)/length(timp_c2), " ore;",style="color:black;text-align:justify"),
                       p("Timpul mediu petrecut de un client in sistem: ",sum(timp_t)/length(timp_t), " ore;",style="color:black;text-align:justify"),
                       width=8,style="background-color:lavender;border-radius: 10px")
            ),
            br(),
            fluidRow(column(width=2, icon("hand-point-right","fa-5x"),align="center"),
                     column(
                       p("Numarul mediu de clienti serviti intr-o zi: ",sum(n_clients)/length(n_clients),style="color:black;text-align:justify;margin-top:8px"),
                       p("Primul moment de timp la care se pierde un client: ",t_pierdut,style="color:black;text-align:justify"),
                       p("Numarul mediu de clienti pierduti in coada 1: ",sum(n_pierduti1)/length(n_pierduti1),style="color:black;text-align:justify"),
                       p("Numarul mediu de clienti pierduti in coada 2: ",sum(n_pierduti2)/length(n_pierduti2),style="color:black;text-align:justify"),
                       p("Numarul mediu de clienti pierduti in total: ",sum(n_pierduti_t)/length(n_pierduti_t),style="color:black;text-align:justify"),
                       
                       width=8,style="background-color:lavender;border-radius: 10px")
            ),
            br(),
            fluidRow(column(width=2, icon("hand-point-right","fa-5x"),align="center"),
                     column(
                       p("Castigul mediu zilnic: ",castig_mediu_zilnic,style="color:black;text-align:justify;margin-top:8px"),
                       p("Castigul minim in ",n," zile: ",castig_minim_zilnic,style="color:black;text-align:justify;margin-top:8px"),
                       p("Castigul maxim in ",n," zile: ",castig_maxim_zilnic,style="color:black;text-align:justify;margin-top:8px"),
                       p("Castigul mediu zilnic daca programul incepe cu o ora mai devreme: ",castig_mediu_zilnic_o_ora_mai_devreme,style="color:black;text-align:justify"),
                       p("Diferenta de castig fata de programul obisnuit: ",diferenta_castig_1,style="color:black;text-align:justify"),
                       p("Castigul mediu zilnic daca programul incepe cu o ora mai tarziu: ",castig_mediu_zilnic_o_ora_mai_tarziu,style="color:black;text-align:justify"),
                       p("Diferenta de castig fata de programul obisnuit: ",diferenta_castig_2,style="color:black;text-align:justify"),
                       width=8,style="background-color:lavender;border-radius: 10px")
            ),
            br(),
            fluidRow(column(width=2, icon("hand-point-right","fa-5x"),align="center"),
                     column(
                       p(" Castigul mediu zilnic daca putem avea cu 5 clienti mai multi in prima coada:",castig_mediu_plus5_1,style="color:black;text-align:justify;margin-top:8px"),
                       p("Diferenta de castig fata de programul obisnuit: ",diferenta_castig_plus5_1,style="color:black;text-align:justify"),
                       p(" Castigul mediu zilnic daca putem avea cu 5 clienti mai multi in a doua coada:",castig_mediu_plus5_2,style="color:black;text-align:justify;margin-top:8px"),
                       p("Diferenta de castig fata de programul obisnuit: ",diferenta_castig_plus5_2,style="color:black;text-align:justify"),
                       width=8,style="background-color:lavender;border-radius: 10px")
            ),
            br(),
            
            
   ),
   tabPanel("Timpi asteptare",
            plotOutput("timpi_coada_1"),
            plotOutput("timpi_coada_2"),
            plotOutput("timpi_sistem"),
   ),
   
   tabPanel("Clienti serviti",
            plotOutput("clienti_serviti_coada_1_hist"),
            plotOutput("clienti_serviti_coada_2_hist"),
   ),
   
   tabPanel("Clienti pierduti",
            plotOutput("clienti_pierduti_1"),
            plotOutput("clienti_pierduti_2"),
            plotOutput("clienti_pierduti")
   ),
   
   tabPanel("Castiguri",
            plotOutput("castiguri"),
            plotOutput("venituri")
   )
  )
)

server <- function(input, output) {
  output$timpi_coada_1 <- renderPlot({
    plot(timp_c1,
         main = "Timpii de asteptare in coada 1",
         xlab = "Client", 
         ylab = "Timp de asteptare (ore)",
         pch = 19,
         col="magenta")
  })
  output$timpi_coada_2 <- renderPlot({
    plot(timp_c2,
         main = "Timpii de asteptare in coada 2",
         xlab = "Client", 
         ylab = "Timp de asteptare (ore)",
         pch = 19,
         col="magenta")
  })
  output$timpi_sistem <- renderPlot({
    plot(timp_t,
         main = "Timpii de asteptare in sistem",
         xlab = "Client", 
         ylab = "Timp de asteptare (ore)",
         pch = 19,
         col="magenta")
  })
  
  output$clienti_serviti_coada_1_hist <- renderPlot({
    hist(A1,
         main = "Numarul de clienti serviti la coada 1",
         xlab = "Moment de timp", 
         ylab = "Numar clienti",
         col="magenta")
  })
  
  output$clienti_serviti_coada_2_hist <- renderPlot({
    hist(A2,
         main = "Numarul de clienti serviti la coada 2",
         xlab = "Moment de timp", 
         ylab = "Numar clienti",
         col="magenta")
  })
  
  output$timpi_pierderi_1 <- renderPlot({
    plot(timp_clienti_pierduti_1,
         main = "Momentele de timp in care s-a pierdut un client in coada 1",
         xlab = "Client", 
         ylab = "Moment de timp",
         pch = 19,
         col="magenta")
  })
  
  output$timpi_pierderi_2 <- renderPlot({
    plot(timp_clienti_pierduti_2,
         main = "Momentele de timp in care s-a pierdut un client in coada 2",
         xlab = "Client", 
         ylab = "Moment de timp",
         pch = 19,
         col="magenta")
  })

  
  output$clienti_pierduti_1 <- renderPlot({
    hist(timp_clienti_pierduti_1,
         main = "Numarul de clienti pierduti la coada 1",
         xlab = "Moment de timp", 
         ylab = "Numar clienti",
         col="magenta")
  })
  
  output$clienti_pierduti_2 <- renderPlot({
    hist(timp_clienti_pierduti_2,
         main = "Numarul de clienti pierduti la coada 2",
         xlab = "Moment de timp", 
         ylab = "Numar clienti",
         col="magenta")
  })
  
  output$clienti_pierduti <- renderPlot({
    hist(timp_clienti_pierduti,
         main = "Numarul de clienti pierduti in total",
         xlab = "Moment de timp", 
         ylab = "Numar clienti",
         col="magenta")
  })
  
  output$castiguri <- renderPlot({
    barplot(c(castig_minim_zilnic,
              castig_mediu_zilnic,
              castig_maxim_zilnic,
            castig_mediu_zilnic_o_ora_mai_devreme,
            castig_mediu_zilnic_o_ora_mai_tarziu,
            castig_mediu_plus5_1,
            castig_mediu_plus5_2),
            main = "Castigurile medii in 1000 zile",
            names.arg=c("Minim zilnic",
                        "Mediu zilnic",
                        "Maxim zilnic",
                        "1h mai devreme",
                        "1h mai tarziu",
                        "Prima coada +5",
                        "A doua coada+5"),
            col="magenta")
  })
  
  output$venituri <- renderPlot({
    plot(venit,
         main = "Veniturile obtinute de la fiecare client",
         xlab = "Client", 
         ylab = "Venit",
         col="magenta")
  })
}

shinyApp(ui, server)

