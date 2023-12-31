#' The AggregatedDotPlot class
#'
#' Implements an aggregated dot plot where each feature/group combination is represented by a dot.
#' The color of the dot scales with the mean assay value across all samples for a given group,
#' while the size of the dot scales with the proportion of non-zero values across samples in that group.
#'
#' @section Slot overview:
#' The following slots control the choice of features:
#' \itemize{
#' \item \code{CustomRows}, a logical scalar indicating whether custom rows in \code{CustomRowsText} should be used.
#' If \code{TRUE}, the feature identities are extracted from the \code{CustomRowsText} slot;
#' otherwise they are defined from a transmitted row selection.
#' Defaults to \code{TRUE}.
#' \item \code{CustomRowsText}, a string containing the names of the features of interest,
#' typically corresponding to the row names of the \linkS4class{SummarizedExperiment}.
#' Names should be new-line separated within this string.
#' Defaults to the name of the first row in the SummarizedExperiment.
#' }
#'
#' The following slots control the specification of groups:
#' \itemize{
#' \item \code{ColumnDataLabel}, a string specifying the name of the \code{\link{colData}} field to use to group cells.
#' The chosen field should correspond to a categorical factor.
#' Defaults to the first categorical field.
#' \item \code{ColumnDataFacet}, a string specifying the name of the \code{\link{colData}} field to use for faceting.
#' The chosen field should correspond to a categorical factor.
#' Defaults to \code{"---"}, i.e., no faceting.
#' }
#'
#' The following slots control the choice of assay values:
#' \itemize{
#' \item \code{Assay}, a string specifying the name of the assay containing continuous values,
#' to use for calculating the mean and the proportion of non-zero values.
#' Defaults to the first valid assay name.
#' }
#'
#' The following slots control the visualization parameters:
#' \itemize{
#' \item \code{VisualBoxOpen}, a logical scalar indicating whether the visual parameter box should be open on initialization.
#' Defaults to \code{FALSE}.
#' \item \code{VisualChoices}, a character vector specifying the visualization options to show.
#' Defaults to \code{"Color"} but can also include \code{"Transform"} and \code{"Legend"}.
#' }
#'
#' The following slots control the transformation of the mean values:
#' \itemize{
#' \item \code{MeanNonZeroes}, a logical scalar indicating whether the mean should only be computed over non-zero values.
#' Defaults to \code{FALSE}.
#' \item \code{Center}, a logical scalar indicating whether the means for each feature should be centered across all groups.
#' Defaults to \code{FALSE}.
#' \item \code{Scale}, a logical scalar indicating whether the standard deviation for each feature across all groups should be scaled to unity.
#' Defaults to \code{FALSE}.
#' }
#'
#' The following slots control the color:
#' \itemize{
#' \item \code{UseCustomColormap}, a logical scalar indicating whether to use a custom color scale.
#' Defaults to \code{FALSE}, in which case the application-wide color scale defined by \code{\link{ExperimentColorMap}} is used.
#' \item \code{CustomColorLow}, a string specifying the low color (i.e., at an average of zero) for a custom scale.
#' Defaults to \code{"grey"}.
#' \item \code{CustomColorHigh}, a string specifying the high color for a custom scale.
#' Defaults to \code{"red"}.
#' \item \code{CenteredColormap}, a string specifying the divergent colormap to use when \code{Center} is \code{TRUE}.
#' Defaults to \code{"blue < grey < orange"}; other choices are \code{"purple < black < yellow"}, \code{"blue < grey < red"} and \code{"green < grey < red"}.
#' }
#'
#' In addition, this class inherits all slots from its parent \linkS4class{Panel} class.
#'
#' @section Constructor:
#' \code{AggregatedDotPlot(...)} creates an instance of a AggregatedDotPlot class,
#' where any slot and its value can be passed to \code{...} as a named argument.
#'
#' @section Supported methods:
#' In the following code snippets, \code{x} is an instance of an AggregatedDotPlot class.
#' Refer to the documentation for each method for more details on the remaining arguments.
#'
#' For setting up data values:
#' \itemize{
#' \item \code{\link{.cacheCommonInfo}(x)} adds a \code{"AggregatedDotPlot"} entry
#' containing \code{continuous.assay.names} and \code{discrete.colData.names}.
#' \item \code{\link{.refineParameters}(x, se)} returns \code{x} after setting \code{"Assay"},
#' \code{"ColumnDataLabel"} and \code{"ColumnDataFacet"} to valid values.
#' If continuous assays or discrete \code{\link{colData}} variables are not available, \code{NULL} is returned instead.
#' }
#'
#' For defining the interface:
#' \itemize{
#' \item \code{\link{.defineInterface}(x, se, select_info)} creates an interface to modify the various parameters in the slots,
#' mostly by calling the parent method and adding another visualization parameter box.
#' \item \code{\link{.defineDataInterface}(x, se, select_info)} creates an interface to modify the data-related parameters,
#' i.e., those that affect the position of the points.
#' \item \code{\link{.defineOutput}(x)} defines the output HTML element.
#' \item \code{\link{.panelColor}(x)} will return the specified default color for this panel class.
#' \item \code{\link{.fullName}(x)} will return \code{"Aggregated dot plot"}.
#' \item \code{\link{.hideInterface}(x)} will return \code{TRUE} for UI elements related to multiple row selections.
#' }
#'
#' For monitoring reactive expressions:
#' \itemize{
#' \item \code{\link{.createObservers}(x, se, input, session, pObjects, rObjects)} will create all relevant observers for the UI elements.
#' }
#'
#' For generating output:
#' \itemize{
#' \item \code{\link{.generateOutput}(x, se, all_memory, all_contents)} will return the aggregated dot plot as a \link{ggplot} object,
#' along with the commands used for its creation.
#' \item \code{\link{.renderOutput}(x, se, output, pObjects, rObjects)} will render the aggregated dot plot onto the interface.
#' \item \code{\link{.exportOutput}(x, se, all_memory, all_contents)} will save the aggregated dot plot to a PDF file named after \code{x},
#' returning the path to the new file.
#' }
#'
#' For providing documentation:
#' \itemize{
#' \item \code{\link{.definePanelTour}(x)} will return a data.frame to be used in \pkg{rintrojs} as a panel-specific tour.
#' }
#'
#' @author Aaron Lun
#'
#' @seealso
#' \linkS4class{Panel}, for the immediate parent class.
#'
#' \linkS4class{ComplexHeatmapPlot}, for another panel with multi-row visualization capability.
#'
#' @examples
#' library(scRNAseq)
#'
#' # Example data ----
#' sce <- ReprocessedAllenData(assays="tophat_counts")
#' class(sce)
#'
#' library(scater)
#' sce <- logNormCounts(sce, exprs_values="tophat_counts")
#'
#' # launch the app itself ----
#' if (interactive()) {
#'     iSEE(sce, initial=list(
#'         AggregatedDotPlot(ColumnDataLabel="Primary.Type")
#'     ))
#' }
#'
#' @name AggregatedDotPlot
#' @docType methods
#' @aliases
#' AggregatedDotPlot-class
#' .cacheCommonInfo,AggregatedDotPlot-method
#' .refineParameters,AggregatedDotplot-method
#' .defineOutput,AggregatedDotPlot-method
#' .generateOutput,AggregatedDotPlot-method
#' .renderOutput,AggregatedDotPlot-method
#' .exportOutput,AggregatedDotPlot-method
#' .defineDataInterface,AggregatedDotPlot-method
#' .defineInterface,AggregatedDotPlot-method
#' .hideInterface,AggregatedDotPlot-method
#' .panelColor,AggregatedDotPlot-method
#' .fullName,AggregatedDotPlot-method
#' .generateOutput,AggregatedDotPlot-method
#' .definePanelTour,AggregatedDotPlot-method
#' .createObservers,AggregatedDotPlot-method
#' .refineParameters,AggregatedDotPlot-method
#' initialize,AggregatedDotPlot-method
NULL

.ADPAssay <- "Assay"
.ADPCustomFeatNames <- "CustomRows"
.ADPFeatNameText <- "CustomRowsText"
.ADPClusterFeatures <- "ClusterRows"

.ADPColDataLabel <- "ColumnDataLabel"
.ADPColDataFacet <- "ColumnDataFacet"

.visualParamChoice <- "VisualChoices"
.visualParamBoxOpen <- "VisualBoxOpen"

.ADPCustomColor <- "UseCustomColormap"
.ADPColorLower <- "CustomColorLow"
.ADPColorUpper <- "CustomColorHigh"
.ADPColorCentered <- "DivergentColormap"

.ADPExpressors <- "MeanNonZeroes"
.ADPCenter <- "Center"
.ADPScale <- "Scale"

.ADPClusterFeatures <- "ClusterRows"
.ADPClusterDistanceFeatures <- "ClusterRowsDistance"
.ADPClusterMethodFeatures <- "ClusterRowsMethod"

collated <- character(0)

collated[.ADPAssay] <- "character"
collated[.ADPCustomFeatNames] <- "logical"
collated[.ADPFeatNameText] <- "character"

collated[.ADPColDataLabel] <- "character"
collated[.ADPColDataFacet] <- "character"

collated[.visualParamChoice] <- "character"
collated[.visualParamBoxOpen] <- "logical"
collated[.ADPColorUpper] <- "character"
collated[.ADPColorLower] <- "character"
collated[.ADPColorCentered] <- "character"
collated[.ADPCustomColor] <- "logical"

collated[.ADPExpressors] <- "logical"
collated[.ADPCenter] <- "logical"
collated[.ADPScale] <- "logical"

collated[.ADPClusterFeatures] <- "logical"
collated[.ADPClusterDistanceFeatures] <- "character"
collated[.ADPClusterMethodFeatures] <- "character"

#' @export
setClass("AggregatedDotPlot", contains="Panel", slots=collated)

#' @export
AggregatedDotPlot <- function(...) {
    new("AggregatedDotPlot", ...)
}

.visualParamChoiceColorTitle <- "Color"
.visualParamChoiceTransformTitle <- "Transform"
.visualParamChoiceLegendTitle <- "Legend"

.centered_color_choices <- c("purple < black < yellow", "blue < grey < orange", "blue < grey < red", "green < grey < red")

#' @export
#' @importFrom methods callNextMethod
setMethod("initialize", "AggregatedDotPlot", function(.Object, ...) {
    args <- list(...)

    args <- .emptyDefault(args, .ADPAssay, getPanelDefault("Assay"))
    args <- .emptyDefault(args, .ADPCustomFeatNames, TRUE)
    args <- .emptyDefault(args, .ADPFeatNameText, NA_character_)

    vals <- args[[.ADPFeatNameText]]
    if (length(vals)!=1L) {
        args[[.ADPFeatNameText]] <- paste(vals, collapse="\n")
    }

    args <- .emptyDefault(args, .ADPColDataLabel, NA_character_)
    args <- .emptyDefault(args, .ADPColDataFacet, iSEE:::.noSelection)

    args <- .emptyDefault(args, .ADPClusterFeatures, FALSE)
    args <- .emptyDefault(args, .ADPClusterDistanceFeatures, .clusterDistanceEuclidean)
    args <- .emptyDefault(args, .ADPClusterMethodFeatures, .clusterMethodWardD2)

    args <- .emptyDefault(args, .visualParamChoice, .visualParamChoiceColorTitle)
    args <- .emptyDefault(args, .visualParamBoxOpen, FALSE)

    args <- .emptyDefault(args, .ADPCustomColor, FALSE)
    args <- .emptyDefault(args, .ADPColorLower, "grey")
    args <- .emptyDefault(args, .ADPColorUpper, "red")
    args <- .emptyDefault(args, .ADPColorCentered, .centered_color_choices[2])

    args <- .emptyDefault(args, .ADPExpressors, FALSE)
    args <- .emptyDefault(args, .ADPCenter, FALSE)
    args <- .emptyDefault(args, .ADPScale, FALSE)

    do.call(callNextMethod, c(list(.Object), args))
})

#' @importFrom S4Vectors setValidity2
setValidity2("AggregatedDotPlot", function(object) {
    msg <- character(0)

    msg <- .singleStringError(msg, object,
        c(
            .ADPAssay,
            .ADPFeatNameText,
            .ADPColDataLabel,
            .ADPColDataFacet,
            .ADPClusterDistanceFeatures,
            .ADPClusterMethodFeatures
        )
    )

    msg <- .validStringError(msg, object,
        c(
            .ADPColorUpper,
            .ADPColorLower
        )
    )

    msg <- .allowableChoiceError(msg, object, .ADPColorCentered, .centered_color_choices)

    msg <- .multipleChoiceError(msg, object, .visualParamChoice,
        c(
            .visualParamChoiceColorTitle,
            .visualParamChoiceTransformTitle,
            .visualParamChoiceLegendTitle
        )
    )

    msg <- .validLogicalError(msg, object,
        c(
            .ADPCustomFeatNames,
            .visualParamBoxOpen,
            .ADPCustomColor,
            .ADPExpressors,
            .ADPCenter,
            .ADPScale,
            .ADPClusterFeatures
        )
    )

    if (length(msg)) {
        return(msg)
    }
    TRUE
})

#' @export
#' @importFrom methods callNextMethod
#' @importFrom SummarizedExperiment assayNames colData
setMethod(".cacheCommonInfo", "AggregatedDotPlot", function(x, se) {
    if (!is.null(.getCachedCommonInfo(se, "AggregatedDotPlot"))) {
        return(se)
    }

    se <- callNextMethod()

    named_assays <- assayNames(se)
    named_assays <- named_assays[named_assays!=""]
    assays_continuous <- vapply(named_assays, .isAssayNumeric, logical(1), se=se)

    df <- colData(se)
    coldata_displayable <- .findAtomicFields(df)
    subdf <- df[,coldata_displayable,drop=FALSE]
    coldata_discrete <- .whichGroupable(subdf)

    .setCachedCommonInfo(se, "AggregatedDotPlot",
        continuous.assay.names=named_assays[assays_continuous],
        discrete.colData.names=coldata_displayable[coldata_discrete])
})

#' @export
#' @importFrom methods callNextMethod
setMethod(".refineParameters", "AggregatedDotPlot", function(x, se) {
    x <- callNextMethod()
    if (is.null(x)) {
        return(NULL)
    }

    if (nrow(se)==0L) {
        warning(sprintf("no rows available for plotting '%s'", class(x)[1]))
        return(NULL)
    }

    all_assays <- .getCachedCommonInfo(se, "AggregatedDotPlot")$continuous.assay.names
    if (length(all_assays)==0L) {
        warning(sprintf("no valid 'assays' for plotting '%s'", class(x)[1]))
        return(NULL)
    }

    x <- .replaceMissingWithFirst(x, .ADPAssay, all_assays)

    if (is.na(x[[.ADPFeatNameText]])) {
        x[[.ADPFeatNameText]] <- rownames(se)[1]
    }

    all_coldata <- .getCachedCommonInfo(se, "AggregatedDotPlot")$discrete.colData.names
    if (!length(all_coldata)) {
        warning(sprintf("no discrete 'colData' for plotting '%s'", class(x)[1]))
        return(NULL)
    }

    x <- .replaceMissingWithFirst(x, .ADPColDataLabel, all_coldata)
    x <- .replaceMissingWithFirst(x, .ADPColDataFacet, c(iSEE:::.noSelection, all_coldata))

    x
})

#' @export
setMethod(".panelColor", "AggregatedDotPlot", function(x) "#703737FF")

#' @export
setMethod(".fullName", "AggregatedDotPlot", function(x) "Aggregated dot plot")

#' @export
#' @importFrom SummarizedExperiment assay rowData colData
#' @importFrom ggplot2 ggplot geom_point aes_string scale_size
#' theme element_rect element_line element_text element_blank xlab facet_wrap
#' scale_color_gradient scale_color_gradientn scale_color_gradient2
#' @importFrom S4Vectors metadata
#' @importFrom shiny showNotification
setMethod(".generateOutput", "AggregatedDotPlot", function(x, se, all_memory, all_contents) {
    # print(str(x))
    plot_env <- new.env()
    plot_env$se <- se
    plot_env$colormap <- .getCachedCommonInfo(se, ".internal")$colormap

    all_cmds <- list()
    cluster_row_args <- character(0)

    all_cmds$select <- .processMultiSelections(x, all_memory, all_contents, plot_env)
    all_cmds$assay <- .extractAssaySubmatrix(x, se, plot_env,
        use_custom_row_slot=.ADPCustomFeatNames,
        custom_row_text_slot=.ADPFeatNameText)

    # Computing the various statistics.
    col1 <- x[[.ADPColDataLabel]]
    col2 <- x[[.ADPColDataFacet]]
    use.facets <- col2!=iSEE:::.noSelection
    coldata.names <- c(col1, if (use.facets) col2)
    cmd <- sprintf(".group_by <- SummarizedExperiment::colData(se)[.chosen.columns,%s,drop=FALSE];",
        paste(deparse(coldata.names), collapse=""))

    computation <- c(cmd,
        ".averages.se <- scuttle::sumCountsAcrossCells(plot.data, .group_by, average=TRUE, store.number=NULL);",
        ".averages <- SummarizedExperiment::assay(.averages.se);",
        ".n.detected.se <- scuttle::numDetectedAcrossCells(plot.data, .group_by, average=TRUE);",
        ".n.detected <- SummarizedExperiment::assay(.n.detected.se);"
    )

    if (x[[.ADPExpressors]] ){
        computation <- c(computation,
            ".averages <- .averages / .n.detected;",
            ".averages[is.na(.averages)] <- 0;"
        )
    }

    if (x[[.ADPCenter]]) {
        computation <- c(computation,
            sprintf(".averages <- t(scale(t(.averages), center=TRUE, scale=%s));", deparse(x[[.ADPScale]]))
        )
    }

    .textEval(computation, plot_env)
    all_cmds$command <- computation

    # Row clustering.
    unclustered_cmds <- c(".rownames_ordered <- rev(rownames(.averages))")
    if (x[[.ADPClusterFeatures]]) {
        clustering_cmds <- c(
            sprintf(".averages_dist <- dist(.averages, method = %s);", deparse(x[[.ADPClusterDistanceFeatures]])),
            sprintf(".averages_hclust <- hclust(.averages_dist, method = %s);", deparse(x[[.ADPClusterMethodFeatures]])),
            ".rownames_ordered <- rev(rownames(.averages)[.averages_hclust$order]);"
        )
        clustering_cmds <- tryCatch(
            {
                .textEval(clustering_cmds, plot_env)
                clustering_cmds
            },
            error = function(e) {
                showNotification(sprintf("%s\n\nClustering skipped.", e), type = "error", duration = 5)
                clustering_cmds <- unclustered_cmds
                .textEval(clustering_cmds, plot_env)
                clustering_cmds
            }
        )
    } else {
        .textEval(unclustered_cmds, plot_env)
        clustering_cmds <- unclustered_cmds
    }

    all_cmds$clustering <- clustering_cmds

    # Organizing in the plot.data.
    if (use.facets) {
        facet.cmd <- '\n    FacetRow=rep(.levels[,2], each=nrow(.averages)),'
    } else {
        facet.cmd <- ''
    }
    prep.cmds <- c(
       ".levels <- SummarizedExperiment::colData(.averages.se);",
        sprintf("plot.data <- data.frame(
    Feature=factor(rep(rownames(.averages), ncol(.averages)), .rownames_ordered),
    Group=rep(.levels[,1], each=nrow(.averages)),%s
    Average=as.numeric(.averages),
    Detected=as.numeric(.n.detected)
)", facet.cmd)
    )
    .textEval(prep.cmds, plot_env)
    all_cmds$prep <- prep.cmds

    if (!x[[.ADPCenter]]) {
        if (x[[.ADPCustomColor]]) {
            col.cmd <- sprintf(
                'scale_color_gradient(limits = c(0, max(plot.data$Average)), low = %s, high = %s)',
                deparse(x[[.ADPColorLower]]), deparse(x[[.ADPColorUpper]])
            )
        } else {
            col.cmd <- sprintf(
                'scale_color_gradientn(limits = c(0, max(plot.data$Average)),
    colours=assayColorMap(colormap, %s, discrete=FALSE)(21L))',
                deparse(x[[.ADPAssay]])
            )
        }
    } else {
        choice_colors <- x[[.ADPColorCentered]]
        choice_colors <- strsplit(choice_colors, split = " < ", fixed = TRUE)[[1]]
        col.cmd <- sprintf(
            "scale_color_gradient2(low=%s, mid=%s, high=%s)",
            deparse(choice_colors[1]), deparse(choice_colors[2]), deparse(choice_colors[3])
        )
    }

    plot.cmds <- c(
        'dplot <- ggplot(plot.data)',
        'geom_point(aes_string(x = "Group", y = "Feature", size = "Detected", col = "Average"))',
        'scale_size(limits = c(0, max(plot.data$Detected)))',
        col.cmd,
        'theme(panel.background = element_rect(fill = "white"),
    panel.grid.major = element_line(linewidth = 0.5, colour = "grey80"),
    panel.grid.minor = element_line(linewidth = 0.25, colour = "grey80"),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1),
    axis.title.y = element_blank())',
        sprintf('xlab(%s)', deparse(paste0(coldata.names, collapse=", "))),
        if (use.facets) "facet_wrap(~FacetRow, nrow=1)"
    )

    plot.cmds <- paste0(plot.cmds, collapse=" +\n    ")
    plot_out <- .textEval(plot.cmds, plot_env)
    all_cmds$plot <- plot.cmds

    list(commands=all_cmds, contents=plot_env$plot.data, plot=plot_out, varname="dplot")
})

#' @export
#' @importFrom shiny renderPlot tagList
setMethod(".renderOutput", "AggregatedDotPlot", function(x, se, output, pObjects, rObjects) {
    plot_name <- .getEncodedName(x)
    force(se) # defensive programming to avoid difficult bugs due to delayed evaluation.

    # nocov start
    output[[plot_name]] <- renderPlot({
        p.out <- .retrieveOutput(plot_name, se, pObjects, rObjects)
        print(p.out$plot)
    })
    # nocov end

    callNextMethod()
})

#' @export
#' @importFrom grDevices pdf dev.off
setMethod(".exportOutput", "AggregatedDotPlot", function(x, se, all_memory, all_contents) {
    contents <- .generateOutput(x, se, all_memory=all_memory, all_contents=all_contents)
    newpath <- paste0(.getEncodedName(x), ".pdf")

    # These are reasonably satisfactory heuristics:
    # Width = Pixels -> Inches, Height = Bootstrap -> Inches.
    pdf(newpath, width=x[[iSEE:::.organizationHeight]]/75, height=x[[iSEE:::.organizationWidth]]*2)
    print(contents$plot)
    dev.off()

    newpath
})

.dimnamesModalOpen <- "INTERNAL_modal_open"

#' @export
#' @importFrom shiny selectInput radioButtons checkboxInput actionButton br
#' @importFrom methods callNextMethod
setMethod(".defineDataInterface", "AggregatedDotPlot", function(x, se, select_info) {
    panel_name <- .getEncodedName(x)
    .input_FUN <- function(field) { paste0(panel_name, "_", field) }

    all_assays <- .getCachedCommonInfo(se, "AggregatedDotPlot")$continuous.assay.names
    all_coldata <- .getCachedCommonInfo(se, "AggregatedDotPlot")$discrete.colData.names

    .addSpecificTour(class(x), .ADPCustomFeatNames, function(plot_name) {
        data.frame(
            rbind(
                c(
                    element=paste0("#", plot_name, "_", .ADPCustomFeatNames),
                    intro="The most important parameter is the choice of features to show as rows on the plot. If this box is unchecked, the selection is chained to a multiple row selection from another panel - see <i>Selection parameters</i>. Alternatively, we can request a custom set of features by checking this box.<br/><br/><strong>Check this box if it isn't already checked.</strong>."
                ),
                c(
                    element=paste0("#", plot_name, "_", .dimnamesModalOpen),
                    intro="This button opens a modal that allows users to copy and paste their desired set of features. These should match up to the row names in the input <code>SummarizedExperiment</code>."
                )
            )
        )
    })

    .addSpecificTour(class(x), .ADPColDataLabel, function(plot_name) {
        data.frame(
            element=paste0("#", plot_name, "_", .ADPColDataLabel, " + .selectize-control"),
            intro="Another key parameter is to select the column metadata field to use to define our groups of samples. This variable must be categorical, for example a cell type label. To create the plot, we then compute the average assay value and percentage of non-zero observations in each group for each feature."
        )
    })

    .addSpecificTour(class(x), .ADPColDataFacet, function(plot_name) {
        data.frame(
            element=paste0("#", plot_name, "_", .ADPColDataFacet, " + .selectize-control"),
            intro="We can also facet by another column metadata field, if multiple fields are of interest. Averages and proportions are then computed for each group within each facet. The faceting variable must also be categorical."
        )
    })

    # TODO: inherit these from a virtual CHMP plot in iSEE.
    .addSpecificTour(class(x)[1], .ADPAssay, function(plot_name) {
        data.frame(
            element = paste0("#", plot_name, "_", .ADPAssay, " + .selectize-control"),
            intro = "Here, we can select the name of the assay matrix to show.
The choices are extracted from the <code>assayNames</code> of a <code>SummarizedExperiment</code> object.
These matrices should be loaded into the object prior to calling <strong>iSEE</strong> - they are not computed on the fly."
        )
    })

    .addSpecificTour(class(x)[1], .ADPClusterFeatures, function(plot_name) {
        data.frame(
            element = paste0("#", plot_name, "_", .ADPClusterFeatures),
            intro = "Features displayed as rows in plot can be (i) clustered dynamically using a selection of distance metrics and clustering methods, or (ii) shown in the order they appear in <code>rownames</code>. The former choice is enabled by checking this box.<br/><br/>
The clustering itself is done on the group averages using <code>hclust</code>, i.e., hierarchical clustering. This is simple and intuitive but not particularly efficient, so should only be used for small numbers of features.<br/><br/>
<strong>Click on this checkbox to cluster dynamically.</strong>"
        )
    })

    .addSpecificTour(class(x)[1], .ADPClusterDistanceFeatures, function(plot_name) {
        data.frame(
            element = paste0("#", plot_name, "_", .ADPClusterDistanceFeatures, " + .selectize-control"),
            intro = "Here we can choose from a variety of different metrics to compute distances between features based on their assay values. The resulting distance is then used in <code>hclust</code> to perform hierarchical clustering. Euclidean distances are probably most common; the Spearman distance is another popular choice that is more robust to outliers."
        )
    })

    .addSpecificTour(class(x)[1], .ADPClusterMethodFeatures, function(plot_name) {
        data.frame(
            element = paste0("#", plot_name, "_", .ADPClusterMethodFeatures, " + .selectize-control"),
            intro = "We can also choose from a variety of different clustering methods. Ward's method and complete linkage clustering are popular choices as they tend to yield more compact and interpretable clusters."
        )
    })

    list(
        .selectInput.iSEE(x, .ADPAssay, label="Assay:",
            choices=all_assays, selected=x[[.ADPAssay]]),
        .checkboxInput.iSEE(x, .ADPCustomFeatNames, label="Use custom rows",
            value=x[[.ADPCustomFeatNames]]),
        .conditionalOnCheckSolo(
            .input_FUN(.ADPCustomFeatNames),
            on_select=TRUE,
            actionButton(.input_FUN(.dimnamesModalOpen), label="Edit feature names"),
            br(), br()
        ),
        .checkboxInput.iSEE(x, .ADPClusterFeatures, label="Cluster rows (on averages)",
            value=x[[.ADPClusterFeatures]]),
        .conditionalOnCheckSolo(
            .input_FUN(.ADPClusterFeatures),
            on_select=TRUE,
            .selectInput.iSEE(x, .ADPClusterDistanceFeatures, label="Clustering distance for rows",
                choices=c(.clusterDistanceEuclidean,  .clusterDistanceMaximum, .clusterDistanceManhattan,
                    .clusterDistanceCanberra, .clusterDistanceBinary, .clusterDistanceMinkowski),
                selected=x[[.ADPClusterDistanceFeatures]]),
            .selectInput.iSEE(x, .ADPClusterMethodFeatures, label="Clustering method for rows",
                choices=c(.clusterMethodWardD, .clusterMethodWardD2, .clusterMethodSingle, .clusterMethodComplete,
                    "average (= UPGMA)"=.clusterMethodAverage,
                    "mcquitty (= WPGMA)"=.clusterMethodMcquitty,
                    "median (= WPGMC)"=.clusterMethodMedian,
                    "centroid (= UPGMC)"=.clusterMethodCentroid),
                selected=x[[.ADPClusterMethodFeatures]])),
        .selectInput.iSEE(x, .ADPColDataLabel, label="Column label:",
            selected=x[[.ADPColDataLabel]], choices=all_coldata),
        .selectInput.iSEE(x, .ADPColDataFacet, label="Column facet:",
            selected=x[[.ADPColDataFacet]], choices=c(iSEE:::.noSelection, all_coldata))
    )
})

#' @export
#' @importFrom colourpicker colourInput
#' @importFrom shiny checkboxGroupInput
setMethod(".defineInterface", "AggregatedDotPlot", function(x, se, select_info) {
    out <- callNextMethod()
    plot_name <- .getEncodedName(x)

    .input_FUN <- function(field) { paste0(plot_name, "_", field) }
    pchoice_field <- .input_FUN(.visualParamChoice)
    center_field <- .input_FUN(.ADPCenter)
    custom_field <- .input_FUN(.ADPCustomColor)

    .addSpecificTour(class(x), .ADPExpressors, function(plot_name) {
        data.frame(
            element=paste0("#", plot_name, "_", .ADPExpressors),
            intro="Checking this box will compute the mean assay value for each group across the non-zero values only. This can provide more information about the distribution at the cost of consistency with other applications that just use the average across all values in each group."
        )
    })

    .addSpecificTour(class(x), .ADPCenter, function(plot_name) {
        data.frame(
            element=paste0("#", plot_name, "_", .ADPCenter),
            intro="Here, we can center the means for each feature, which mimics the visualization that we might see for a heatmap. This provides better coloration to explore differences between means, though it becomes more complex to interpret this color scale in combination with the changes in size of the dots."
        )
    })

    .addSpecificTour(class(x), .ADPScale, function(plot_name) {
        data.frame(
            element=paste0("#", plot_name, "_", .ADPScale),
            intro="If centering is enabled, we can also turn on scaling of the centered means. This means that the colors now correspond to z-scores."
        )
    })

    .addSpecificTour(class(x)[1], .ADPColorCentered, function(plot_name) {
        data.frame(
            element = paste0("#", plot_name, "_", .ADPColorCentered, " + .selectize-control"),
            intro = "Here, we can select from a choice of diverging color maps when row values are centered. This enables convenient visualizations of deviations from the mean, especially when the values are also scaled."
        )
    })

    .addSpecificTour(class(x), .ADPCustomColor, function(plot_name) {
        data.frame(
            rbind(
                c(
                    element=paste0("#", plot_name, "_", .ADPCustomColor),
                    intro="By default, we use the color map for the chosen assay in the <code>ExperimentColorMap</code>, passed to <strong>iSEE</strong> during app start-up. However, if this box is checked, we can specify our own color scale in terms of the lower and upper colors. <strong>Check this box.</strong>"
                ),
                c(
                    element=paste0("#", plot_name, "_", .ADPColorLower),
                    intro="Here, we can choose the lower color, i.e., at zero."
                ),
                c(
                    element=paste0("#", plot_name, "_", .ADPColorUpper),
                    intro="Here, we can choose the upper color, to be used at the maximum average assay value among all selected features. We then interpolate between the lower and upper boundaries to obtain colors for all other values."
                )
            )
        )
    })

    c(
        out[1],
        list(
            collapseBox(
                id=.input_FUN(.visualParamBoxOpen),
                title="Visual parameters",
                open=x[[.visualParamBoxOpen]],
                checkboxGroupInput(
                    inputId=pchoice_field,
                    label=NULL,
                    inline=TRUE,
                    selected=x[[.visualParamChoice]],
                    choices=c(
                        .visualParamChoiceColorTitle,
                        .visualParamChoiceTransformTitle
                    )
#                        .visualParamChoiceLegendTitle) # TODO: add this.
                ),
                .conditionalOnCheckGroup(
                    pchoice_field,
                    .visualParamChoiceColorTitle,
                    hr(),
                    .conditionalOnCheckSolo(
                        center_field,
                        on_select=FALSE,
                        .checkboxInput.iSEE(x, .ADPCustomColor,
                            label="Use custom colors",
                            value=x[[.ADPCustomColor]]),
                        .conditionalOnCheckSolo(
                            custom_field,
                            on_select=TRUE,
                            colourInput(.input_FUN(.ADPColorLower),
                                label="Lower color",
                                value=x[[.ADPColorLower]]),
                            colourInput(.input_FUN(.ADPColorUpper),
                                label="Upper color",
                                value=x[[.ADPColorUpper]])
                        )
                    ),
                    .conditionalOnCheckSolo(
                        center_field,
                        on_select=TRUE,
                        .selectInput.iSEE(x, .ADPColorCentered,
                            label="Divergent colormap",
                            selected=x[[.ADPColorCentered]],
                            choices=.centered_color_choices
                        )
                    )
                ),
                .conditionalOnCheckGroup(
                    pchoice_field,
                    .visualParamChoiceTransformTitle,
                    hr(),
                    .checkboxInput.iSEE(x, .ADPExpressors,
                        label="Compute average expression over non-zero samples",
                        value=x[[.ADPExpressors]]),
                    .checkboxInput.iSEE(x, .ADPCenter,
                        label="Center averages",
                        value=x[[.ADPCenter]]),
                    .conditionalOnCheckSolo(
                        center_field,
                        on_select=TRUE,
                        .checkboxInput.iSEE(x, .ADPScale,
                            label="Scale averages",
                            value=x[[.ADPScale]])
                    )
                )
            )
        ),
        out[-1]
    )
})

#' @importFrom shiny plotOutput
#' @export
setMethod(".defineOutput", "AggregatedDotPlot", function(x) {
    plot_name <- .getEncodedName(x)
    plotOutput(plot_name, height=paste0(x[[iSEE:::.organizationHeight]], "px"))
})

#' @export
setMethod(".createObservers", "AggregatedDotPlot", function(x, se, input, session, pObjects, rObjects) {
    callNextMethod()

    plot_name <- .getEncodedName(x)

    # Not much point distinguishing between protected and unprotected here,
    # as there aren't any selections transmitted from this panel anyway.
    .createProtectedParameterObservers(plot_name,
        fields=c(.ADPCustomFeatNames,
            .ADPClusterFeatures,
            .ADPClusterDistanceFeatures,
            .ADPClusterMethodFeatures),
        input=input, pObjects=pObjects, rObjects=rObjects)

    .createUnprotectedParameterObservers(plot_name,
        fields=c(.ADPColDataLabel, .ADPColDataFacet,
            .ADPAssay,
            .ADPColorUpper, .ADPColorLower, .ADPCustomColor, .ADPColorCentered,
            .ADPExpressors, .ADPCenter, .ADPScale),
        input=input, pObjects=pObjects, rObjects=rObjects)

    .createCustomDimnamesModalObservers(plot_name, .ADPFeatNameText, .dimnamesModalOpen, se,
        input=input, session=session, pObjects=pObjects, rObjects=rObjects, source_type="row")

    invisible(NULL)
})

#' @export
setMethod(".hideInterface", "AggregatedDotPlot", function(x, field) {
    if (field %in% c(iSEE:::.multiSelectHistory)) {
        TRUE
    } else {
        callNextMethod()
    }
})

#' @export
setMethod(".definePanelTour", "AggregatedDotPlot", function(x) {
    rbind(
        c(paste0("#", .getEncodedName(x)), sprintf("The <font color=\"%s\">AggregatedDotPlot</font> panel displays an aggregated dot plot that visualizes the mean assay value along with the proportion of non-zero values, for each of multiple features in each of multiple groups of samples. This is strictly an end-point panel, i.e., it cannot transmit to other panels.", .getPanelColor(x))),
        .addTourStep(x, iSEE:::.dataParamBoxOpen, "The <i>Data parameters</i> box shows the available parameters that can be tweaked to control the data in the aggregated dot plot.<br/><br/><strong>Action:</strong> click on this box to open up available options."),
        .addTourStep(x, .visualParamBoxOpen, "The <i>Visual parameters</i> box shows the available visual parameters that can be tweaked in this plot.<br/><br/><strong>Action:</strong> click on this box to open up available options."),
        .addTourStep(x, .visualParamChoice, "A large number of options are available here, so not all of them are shown by default. We can check some of the boxes here to show or hide some classes of parameters.<br/><br/><strong>Action:</strong> check the <i>Transform</i> box to expose some transformation options."),
        callNextMethod()
    )
})
