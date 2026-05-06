#install the data from the textbook onto your computer#
install.packages("fpp3")
install.packages("ggtext")
install.packages("patchwork")


#locate where the packages are installed on your computer#
library (fpp3)

#In case I can't find the file easily#
file.choose()

#load a .csv file into R. Place in quatations inside the parenthesis# 
tute1 <- readr::read_csv("C:/Users/Owner/Documents/GitHub/College Transcripts Data Analysis/college-transcript-analysis/Combined_Transcripts.csv")

#Convert the data into time series data
View(tute1)

#Here are the library packages I've had to add#
library(ggplot2)
library(dplyr)
library(ggtext)
library(patchwork)

# ============================================================
# CHART 1: Combined Transcripts Grade Distribution
# ============================================================

#This is to graph my combined transcripts from both colleges based on grade#
ggplot(tute1, aes(x = factor(Grade, levels = c("A+", "A", "B", "C", "D", "F", "CR", "NC", "W")))) +
  geom_bar(fill = "steelblue") +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  labs(title = "Grade Distribution", 
       subtitle = paste("Total Classes of College Career:", nrow(tute1)),
       x = "Grade", 
       y = "Number of Classes",
       caption = "CR = Credit (passed Oral & Practical exams for A&P license)\nNC = No Credit \nW = Withdrawn") +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, size = 10),
        plot.caption = element_text(hjust = 0, size = 9))

# ============================================================
# CHART 2: MSU Denver Grade Distribution
# ============================================================

#This graphs only MSU Denver grades#
tute1 |>
  filter(Institution == "MSU Denver") |>
  mutate(Grade = factor(Grade, levels = c("A+", "A", "B", "W"))) |>
  ggplot(aes(x = Grade)) +
  geom_bar(fill = "steelblue") +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  labs(title = "MSU Denver Grade Distribution", 
       subtitle = "Total Classes at MSU Denver: 28",
       x = "Grades<br><span style='font-size:9pt'>Final GPA: 3.950</span>", 
       y = "Number of Classes") +
  theme(plot.title = element_text(hjust = 0.5),
      plot.subtitle = element_text(hjust = 0.5, size = 10),
      axis.title.x = ggtext::element_markdown())

# ============================================================
# CHART 3: Online vs In-Person Classes (with timeline)
# ============================================================

# Fill in the Campus blanks for TCC as "In-Person"
online_data <- tute1 |>
  mutate(Campus = ifelse(is.na(Campus) | Campus == "", "In-Person", Campus),
         Campus = ifelse(Campus == "Online", "Online", "In-Person"))

# Build a chronological term order
term_order <- online_data |>
  mutate(year = as.numeric(substr(Term, nchar(Term)-3, nchar(Term))),
         season = case_when(
           grepl("Spring", Term) ~ 1,
           grepl("Summer", Term) ~ 2,
           grepl("Fall", Term)   ~ 3
         ),
         sort_key = year * 10 + season) |>
  distinct(Term, sort_key) |>
  arrange(sort_key) |>
  pull(Term)

online_data <- online_data |>
  mutate(Term = factor(Term, levels = term_order))

# TIMELINE: Stacked bars by term
timeline <- online_data |>
  ggplot(aes(x = Term, fill = Campus)) +
  geom_bar() +
  scale_fill_manual(values = c("Online" = "darkgreen", "In-Person" = "steelblue")) +
  labs(title = "Class Format Through My College Years",
       subtitle = "Recent years show my adaptation to online",
       x = "Term",
       y = "Number of Classes",
       fill = "Format") +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, size = 10),
        axis.text.x = element_text(angle = 45, hjust = 1))

# Chart 1: Grade distribution of in-person classes
in_person_only <- online_data |> filter(Campus == "In-Person")

chart1 <- in_person_only |>
  mutate(Grade = factor(Grade, levels = c("A+", "A", "B", "C", "D", "F", "CR", "NC", "W"))) |>
  ggplot(aes(x = Grade)) +
  geom_bar(fill = "steelblue") +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  labs(title = "Grades in In-Person Classes",
       subtitle = paste("Total In-Person Classes:", nrow(in_person_only)),
       x = "Grade", 
       y = "Number of Classes") +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, size = 10)) +
  ylim(0, max(table(in_person_only$Grade)) * 1.15)

# Chart 2: Grade distribution of online classes
online_only <- online_data |> filter(Campus == "Online")

chart2 <- online_only |>
  mutate(Grade = factor(Grade, levels = c("A+", "A", "B", "C", "D", "F", "W"))) |>
  ggplot(aes(x = Grade)) +
  geom_bar(fill = "darkgreen") +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  labs(title = "Grades in Online Classes",
       subtitle = paste("Total Online Classes:", nrow(online_only)),
       x = "Grade", 
       y = "Number of Classes") +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, size = 10)) +
  ylim(0, max(table(online_only$Grade)) * 1.15)

# Display: timeline on top, two charts below
timeline / (chart1 + chart2)


# ============================================================
# CHART 4: Subject Area Diversity
# ============================================================

# Group subjects into broader categories for clarity
subject_data <- tute1 |>
  mutate(Category = case_when(
    Subject %in% c("AERM", "AES")                              ~ "Aviation",
    Subject == "ECO"                                            ~ "Economics",
    Subject %in% c("MTH", "MATH", "AST")                       ~ "Math & Science",
    Subject %in% c("ENG", "ENGL", "COMM", "SPCH")              ~ "English & Communication",
    Subject %in% c("HIS", "HIST", "MUS", "MUSI", "ANT", "NUT", "PSYC") ~ "Humanities & Social Science",
    Subject %in% c("BCIS", "CIS", "BMGT", "MGT")               ~ "Business & Computing",
    TRUE ~ "Other"
  ))

ggplot(subject_data, aes(x = forcats::fct_infreq(Category), fill = Category)) +
  geom_bar() +
  geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.5) +
  labs(title = "Classes divided into Subject Area",
       subtitle = "Breakdown of my classes across aviation, economics, and general education",
       x = "Subject Area",
       y = "Number of Classes",
       caption = paste(
         "Bachelor of Arts in Economics  |  Minor: Aviation Management",
         "Certificate Earned: Airport Management",
         "Honors: Summa Cum Laude  |  Outstanding Economics Student",
         sep = "\n"
       )) +
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5, size = 10),
        plot.caption = element_text(hjust = 0.5, size = 11, face = "bold",
                                    margin = margin(t = 15)),
        axis.text.x = element_text(angle = 35, hjust = 1),
        legend.position = "none") +
  ylim(0, max(table(subject_data$Category)) * 1.15)